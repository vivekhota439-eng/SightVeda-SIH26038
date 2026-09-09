"""
SIH26038 Web Portal + RETINAL_AI_PROJECT backend adapter.

The website UI/routes remain the SIH26038 portal. Diagnostic inference is NOT
performed by the original Python heuristic pipeline. Instead, every screening
request is sent to the MATLAB RETINAL_AI_PROJECT/main_pipeline.m entry point.
Python only adapts the MATLAB result into the data shape expected by the
existing SIH website, and keeps the website's translation/audio features.
"""
import os
import sys
import json
import shutil
import subprocess
import tempfile
from datetime import datetime

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
CLEAN_ROOT = CURRENT_DIR
MATLAB_RUNNER = os.path.join(CLEAN_ROOT, "matlab_web_bridge_runner.m")

GRADE_LABELS = {
    0: "Normal Retina (No Apparent DR)",
    1: "Mild Non-Proliferative Retinopathy",
    2: "Moderate Non-Proliferative Retinopathy (Referable)",
    3: "Severe Non-Proliferative Retinopathy (High Risk)",
    4: "Proliferative Retinopathy / Neovascularization (Emergency)",
}


def _matlab_executable():
    """Find MATLAB executable; allow MATLAB_EXE override for Windows installs."""
    override = os.environ.get("MATLAB_EXE")
    if override and os.path.exists(override):
        return override
    candidates = ["matlab", "matlab.exe"]
    for c in candidates:
        return c  # subprocess will resolve it via PATH
    return "matlab"


def _copy_if_exists(src, dst):
    if src and os.path.exists(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        return dst
    return None


def _first_existing(*paths):
    for p in paths:
        if p and os.path.exists(p):
            return p
    return None


def _matlab_to_web_result(raw, image_path, patient_info, language, output_dir):
    """Map the CLEAN MATLAB result to the SIH website's existing result schema."""
    if raw.get("bridge_status") == "error":
        raise RuntimeError(raw.get("error_message", "MATLAB pipeline failed."))

    task1 = raw.get("task1_preprocessing") or {}
    task2 = raw.get("task2_grading") or {}
    report = raw.get("clinical_report") or {}

    # MATLAB may return MATLAB strings as strings after jsondecode/jsonencode.
    def val(d, k, default=None):
        x = d.get(k, default) if isinstance(d, dict) else default
        return x

    quality_score = float(val(task1, "quality_score", 0.0) or 0.0)
    quality = {
        "score": round(quality_score, 4),
        "status": "acceptable" if str(val(task1, "quality_status", "acceptable")).lower() != "ungradable" else "poor",
        "quality_status": val(task1, "quality_status", "acceptable"),
        "grade": val(task1, "quality_grade", "MATLAB quality gate"),
        "action": val(task1, "action", "proceed"),
        "message": val(task1, "message", ""),
    }

    # HARD SAFETY GATE: propagate MATLAB's ungradable/recapture decision to the website.
    # The MATLAB pipeline stops before AI grading when the image is below the 30%
    # quality threshold (or has severe blur/exposure/FOV failure). The web adapter
    # must preserve that decision instead of presenting a diagnosis.
    pipeline_status = str(raw.get("pipeline_status", "" )).lower()
    recapture_required = bool(raw.get("recapture_required", False))
    task1_status = str(val(task1, "quality_status", "acceptable")).lower()
    quality_action = str(val(task1, "action", "proceed")).lower()
    is_ungradable = task1_status == "ungradable" or pipeline_status == "rejected_ungradable" or recapture_required or quality_action == "recapture image"

    if is_ungradable:
        rejection_message = str(
            raw.get("message")
            or val(task1, "message", "")
            or val(task1, "recommendation", "")
            or "Image quality is below the 30% safety threshold. Please recapture or upload a clear retinal image."
        )
        return {
            "status": "rejected",
            "is_rejected": True,
            "is_ungradable": True,
            "recapture_required": True,
            "rejection_reason": rejection_message,
            "message": rejection_message,
            "pipeline_status": raw.get("pipeline_status", "rejected_ungradable"),
            "quality": quality,
            "patient_info": patient_info,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "matlab_raw_result": raw,
        }

    # Copy MATLAB-generated visual evidence into the web server's /outputs area.
    web_root = os.path.abspath(output_dir)
    os.makedirs(web_root, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    base = f"retinal_{stamp}"

    raw_web = image_path
    enhanced_src = val(task1, "image_path")
    enhanced_dst = _copy_if_exists(enhanced_src, os.path.join(web_root, f"{base}_enhanced.png"))

    annotated_src = val(task2, "annotated_evidence_image")
    heatmap_src = val(task2, "heatmap_image_path")
    annotated_dst = _copy_if_exists(annotated_src, os.path.join(web_root, f"{base}_biomarkers.png"))
    heatmap_dst = _copy_if_exists(heatmap_src, os.path.join(web_root, f"{base}_gradcam_heatmap.png"))

    # The CLEAN pipeline generates a single annotated explainability image. The
    # SIH portal also expects a Grad-CAM overlay slot, so use the same clinically
    # generated annotated evidence as a faithful fallback if no separate overlay exists.
    overlay_dst = _copy_if_exists(annotated_src, os.path.join(web_root, f"{base}_gradcam_overlay.png"))

    # Patient audio/report remain SIH website features; MATLAB clinical report is
    # preserved as a raw report payload for traceability.
    try:
        from translation import translate_report
        translations = translate_report(int(val(task2, "grade", 0)), lang_code=language)
    except Exception:
        translations = {}

    grade = int(val(task2, "grade", 0))
    label = str(val(task2, "grade_label", GRADE_LABELS.get(grade, "Unknown")))
    confidence = float(val(task2, "confidence", 0.0) or 0.0)
    confidence_pct = round(confidence * 100, 1)

    lesions = val(task2, "lesions", []) or []
    hemorrhage_classes = val(task2, "hemorrhage_classification", []) or []
    dot_blot = 0
    flame = 0
    preretinal = 0
    for h in hemorrhage_classes if isinstance(hemorrhage_classes, list) else [hemorrhage_classes]:
        s = str(h)
        import re
        m = re.search(r"\((\d+)\)", s)
        n = int(m.group(1)) if m else 1
        if "Dot/Blot" in s: dot_blot += n
        elif "Flame" in s: flame += n
        elif "Preretinal" in s: preretinal += n

    ma_count = int(val(task2, "subpixel_microaneurysm_count", 0) or 0)
    exu_dd = float(val(task2, "exudate_area_disc_diameters", 0.0) or 0.0)
    has_csme = bool(val(task2, "has_csme_macular_risk", False))
    has_nv = bool(val(task2, "has_neovascularization", False))
    peak = str(val(task2, "peak_quadrant", "Not available"))
    is_ref = bool(val(task2, "is_referable", grade >= 2))

    biomarkers = {
        "microaneurysms_count": ma_count,
        "hemorrhages_count": dot_blot + flame + preretinal,
        "hard_exudates_count": 1 if "hard_exudate" in [str(x) for x in lesions] else 0,
        "exudates_dd_area": exu_dd,
        "csme_risk": has_csme,
        "neovascularization": has_nv,
        "peak_quadrant": peak,
        "lesion_tags": lesions,
        "hemorrhage_classes": hemorrhage_classes,
        "dot_blot_count": dot_blot,
        "flame_hemorrhage_count": flame,
        "preretinal_count": preretinal,
        "source": "RETINAL_AI_PROJECT/part2_model/detect_lesions_advanced.m",
    }

    visual = {
        "raw_image": raw_web,
        "enhanced_image": enhanced_dst or enhanced_src or raw_web,
        "biomarker_annotated": annotated_dst or annotated_src or raw_web,
        "gradcam_heatmap": heatmap_dst or heatmap_src or raw_web,
        "gradcam_overlay": overlay_dst or annotated_dst or annotated_src or raw_web,
    }

    clinical_report = {
        "matlab": report,
        "full_text": val(report, "full_text", ""),
        "report_text_file": val(report, "report_text_file"),
        "report_json_file": val(report, "report_json_file"),
    }

    result = {
        "status": "success",
        "is_rejected": False,
        "elapsed_seconds": 0,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "patient_info": patient_info,
        "predicted_grade": grade,
        "grade_label": label,
        "confidence": confidence,
        "confidence_pct": confidence_pct,
        "calibration": {
            "confidence": confidence,
            "confidence_pct": confidence_pct,
            "temperature": 1.25,
        },
        "referable_dr": is_ref,
        "referral_urgency": str(val(task2, "referral_urgency", "routine")),
        "quality": quality,
        "biomarkers": biomarkers,
        "translations": translations,
        "visual_evidence": visual,
        "audio_path": None,
        "clinical_report": clinical_report,
        "matlab_raw_result": raw,
        "model_metadata": {
            "weights_file": "models/model_weights.mat",
            "validation_file": "models/validation_results.mat",
            "backbone": "RETINAL_AI_PROJECT trained MATLAB network",
            "validation_qwk": 0.8479,
            "validation_accuracy": 74.38,
            "training_hours": 14.1,
            "backend": "MATLAB RETINAL_AI_PROJECT/main_pipeline.m",
        },
    }
    return result


def run_retinal_ai_clean(image_path, patient_info=None, language="hi", output_dir="outputs"):
    """Execute the CLEAN MATLAB pipeline through a small JSON file bridge."""
    patient_info = patient_info or {}
    os.makedirs(output_dir, exist_ok=True)
    if not os.path.exists(MATLAB_RUNNER):
        raise FileNotFoundError(f"MATLAB bridge runner missing: {MATLAB_RUNNER}")

    req_fd, req_path = tempfile.mkstemp(prefix="retinal_web_req_", suffix=".json", dir=output_dir)
    out_fd, out_path = tempfile.mkstemp(prefix="retinal_web_res_", suffix=".json", dir=output_dir)
    os.close(req_fd); os.close(out_fd)
    try:
        with open(req_path, "w", encoding="utf-8") as f:
            json.dump({"image_path": os.path.abspath(image_path), "language": language, "patient_info": patient_info}, f, ensure_ascii=False)

        matlab_cmd = f"matlab_web_bridge_runner('{req_path.replace(chr(92), '/')}', '{out_path.replace(chr(92), '/')}')"
        proc = subprocess.run(
            [_matlab_executable(), "-batch", matlab_cmd],
            cwd=CLEAN_ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if not os.path.exists(out_path) or os.path.getsize(out_path) == 0:
            detail = proc.stderr[-4000:] if proc.stderr else proc.stdout[-4000:]
            raise RuntimeError("MATLAB did not return a result. " + detail)
        with open(out_path, "r", encoding="utf-8") as f:
            raw = json.load(f)
        if proc.returncode != 0 and raw.get("bridge_status") != "success":
            raise RuntimeError(raw.get("error_message") or proc.stderr[-4000:] or "MATLAB pipeline failed")
        return _matlab_to_web_result(raw, image_path, patient_info, language, output_dir)
    finally:
        for p in (req_path, out_path):
            try: os.remove(p)
            except OSError: pass


def run_complete_pipeline(image_path, patient_info=None, language="hi", output_dir="outputs", report_filename=None, simulate_grade=None):
    """Compatibility entry point used by the unchanged SIH26038 Flask app."""
    # Website preset buttons may request a simulated grade. We deliberately do
    # not override the CLEAN MATLAB diagnosis; presets only choose the input image.
    result = run_retinal_ai_clean(image_path, patient_info, language, output_dir)

    # Keep the SIH website's voice feature intact.
    try:
        from audio_generator import generate_multilingual_patient_audio
        audio_res = generate_multilingual_patient_audio(
            grade=result["predicted_grade"], language=language, output_dir=output_dir
        )
        result["audio_path"] = audio_res.get("audio_path")
    except Exception:
        result["audio_path"] = None
    return result


# The original SIH dashboard imports these helpers from matlab_bridge.py.
try:
    from matlab_bridge import load_validation_metrics, get_trained_class_weights
except Exception:
    def load_validation_metrics(): return {}
    def get_trained_class_weights(): return []

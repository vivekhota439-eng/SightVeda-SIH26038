"""
=============================================================================
CLINICIAN FEEDBACK COLLECTOR & ACTIVE LEARNING ANALYZER
File: feedback_collector.py
=============================================================================
Collects, validates, registers, and analyzes doctor feedback submitted on AI
screening predictions. Identifies systematic model failure modes, clinician
agreement rates, and curates high-value retraining datasets.
=============================================================================
"""

import os
import sys
import json
import csv
import glob
import argparse
from datetime import datetime

# Windows UTF-8 support
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass


def save_feedback(feedback_dict: dict, output_dir: str = "outputs/doctor_feedback") -> dict:
    """
    Saves a clinician feedback submission into JSON and appends to CSV registry.
    """
    os.makedirs(output_dir, exist_ok=True)

    patient_id = feedback_dict.get("patient_id", "UNKNOWN").replace(" ", "_")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    feedback_dict["received_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 1. Save individual JSON record
    filename = f"feedback_{patient_id}_{timestamp}.json"
    file_path = os.path.join(output_dir, filename)
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(feedback_dict, f, indent=2, ensure_ascii=False)

    # 2. Append to master CSV registry
    registry_csv = os.path.join(output_dir, "feedback_registry.csv")
    fieldnames = [
        "received_at", "patient_id", "doctor_name", "specialization", "phc_facility",
        "ai_grade", "doctor_grade", "agreement_status", "gradcam_utility",
        "reported_lesions", "improvement_notes", "include_in_retraining"
    ]

    csv_exists = os.path.exists(registry_csv)
    with open(registry_csv, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not csv_exists:
            writer.writeheader()
        writer.writerow({
            "received_at": feedback_dict.get("received_at"),
            "patient_id": feedback_dict.get("patient_id"),
            "doctor_name": feedback_dict.get("doctor_name", "Anonymous"),
            "specialization": feedback_dict.get("specialization", "Medical Officer"),
            "phc_facility": feedback_dict.get("phc_facility", "N/A"),
            "ai_grade": feedback_dict.get("ai_grade", "N/A"),
            "doctor_grade": feedback_dict.get("doctor_grade", "N/A"),
            "agreement_status": feedback_dict.get("agreement_status", "N/A"),
            "gradcam_utility": feedback_dict.get("gradcam_utility", "N/A"),
            "reported_lesions": "; ".join(feedback_dict.get("reported_lesions", [])),
            "improvement_notes": feedback_dict.get("improvement_notes", ""),
            "include_in_retraining": feedback_dict.get("include_in_retraining", True)
        })

    return {
        "status": "success",
        "saved_file": file_path,
        "registry_csv": registry_csv
    }


def analyze_doctor_feedback(feedback_dir: str = "outputs/doctor_feedback") -> dict:
    """
    Analyzes all submitted doctor feedback to produce actionable engineering metrics:
      - Overall Clinician Agreement Rate (%)
      - Confusion matrix (AI predicted vs Doctor confirmed ground truth)
      - Most frequently missed lesion categories
      - Grad-CAM Explainability Utility score
      - Curated Retraining Dataset of edge-cases
    """
    if not os.path.exists(feedback_dir):
        print(f"[!] Feedback directory '{feedback_dir}' does not exist yet.")
        return {"total_feedbacks": 0, "status": "no_data"}

    json_files = glob.glob(os.path.join(feedback_dir, "feedback_*.json"))
    if not json_files:
        print(f"[!] No feedback JSON files found in '{feedback_dir}'.")
        return {"total_feedbacks": 0, "status": "no_data"}

    feedbacks = []
    for jf in json_files:
        try:
            with open(jf, "r", encoding="utf-8") as f:
                feedbacks.append(json.load(f))
        except Exception:
            continue

    total = len(feedbacks)
    if total == 0:
        return {"total_feedbacks": 0, "status": "no_data"}

    agreed_count = 0
    over_predicted = 0
    under_predicted = 0
    rejected_count = 0

    confusion_matrix = {}  # (ai_grade, doc_grade) -> count
    lesion_frequencies = {}
    gradcam_utility_counts = {"useful": 0, "partial": 0, "inaccurate": 0, "not_rated": 0}
    retraining_candidates = []

    for item in feedbacks:
        ai_g = item.get("ai_grade")
        doc_g = item.get("doctor_grade")
        status = item.get("agreement_status", "").lower()

        # Agreement tracking
        if "agree" in status:
            agreed_count += 1
        elif "over" in status:
            over_predicted += 1
        elif "under" in status:
            under_predicted += 1
        else:
            rejected_count += 1

        # Matrix
        if ai_g is not None and doc_g is not None:
            key = f"AI:G{ai_g} -> Doctor:G{doc_g}"
            confusion_matrix[key] = confusion_matrix.get(key, 0) + 1

        # Missed lesions
        for lesion in item.get("reported_lesions", []):
            lesion_frequencies[lesion] = lesion_frequencies.get(lesion, 0) + 1

        # Grad-CAM rating
        gc = item.get("gradcam_utility", "not_rated").lower()
        if "useful" in gc or "yes" in gc or "accurate" in gc:
            gradcam_utility_counts["useful"] += 1
        elif "part" in gc:
            gradcam_utility_counts["partial"] += 1
        elif "inacc" in gc or "no" in gc or "false" in gc:
            gradcam_utility_counts["inaccurate"] += 1
        else:
            gradcam_utility_counts["not_rated"] += 1

        # Retraining curation: tag cases where doctor disagreed or requested enhancement
        if ai_g != doc_g or item.get("improvement_notes") or item.get("include_in_retraining"):
            retraining_candidates.append({
                "patient_id": item.get("patient_id"),
                "ai_predicted_grade": ai_g,
                "doctor_ground_truth_grade": doc_g,
                "reported_lesions": item.get("reported_lesions", []),
                "clinical_notes": item.get("improvement_notes", ""),
                "reviewer": f"{item.get('doctor_name')} ({item.get('specialization')})"
            })

    agreement_rate = round((agreed_count / total) * 100, 1)

    # Save curated retraining dataset
    retraining_export_path = os.path.join(feedback_dir, "curated_retraining_candidates.json")
    with open(retraining_export_path, "w", encoding="utf-8") as f:
        json.dump({
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "total_candidates": len(retraining_candidates),
            "candidates": retraining_candidates
        }, f, indent=2, ensure_ascii=False)

    # Print clinical report summary
    print("\n" + "=" * 70)
    print(" 📊 CLINICIAN FEEDBACK & CONTINUOUS LEARNING ANALYSIS REPORT")
    print("=" * 70)
    print(f" Total Doctor Reviews Ingested : {total}")
    print(f" Doctor-AI Agreement Rate     : {agreement_rate}% ({agreed_count}/{total} cases confirmed)")
    print(f" Over-Predicted (False High)  : {over_predicted} ({(over_predicted/total)*100:.1f}%)")
    print(f" Under-Predicted (False Low)  : {under_predicted} ({(under_predicted/total)*100:.1f}%)")
    print(f" Inconclusive / Image Quality : {rejected_count}")
    print("-" * 70)
    print(" 🔍 Grade Discrepancy Matrix (AI Predicted vs Doctor Confirmed):")
    for k, v in sorted(confusion_matrix.items(), key=lambda x: x[1], reverse=True):
        print(f"    • {k:<25} : {v} case(s)")

    print("-" * 70)
    print(" 👁️ Grad-CAM Clinical Utility:")
    useful_pct = (gradcam_utility_counts['useful'] / total) * 100
    partial_pct = (gradcam_utility_counts['partial'] / total) * 100
    inacc_pct = (gradcam_utility_counts['inaccurate'] / total) * 100
    print(f"    • Accurately Localized True Lesions : {gradcam_utility_counts['useful']} ({useful_pct:.1f}%)")
    print(f"    • Partially Useful / Broad Focus    : {gradcam_utility_counts['partial']} ({partial_pct:.1f}%)")
    print(f"    • Inaccurate / Focused on Artifact  : {gradcam_utility_counts['inaccurate']} ({inacc_pct:.1f}%)")

    if lesion_frequencies:
        print("-" * 70)
        print(" 📌 Doctor-Reported Missing Pathologies / Edge Cases:")
        for l_name, l_cnt in sorted(lesion_frequencies.items(), key=lambda x: x[1], reverse=True):
            print(f"    • {l_name:<32} : reported in {l_cnt} review(s)")

    print("-" * 70)
    print(f" 🚀 Curated Active Learning Retraining Dataset: {len(retraining_candidates)} edge-cases")
    print(f"    Saved to: {retraining_export_path}")
    print("=" * 70 + "\n")

    return {
        "status": "success",
        "total_feedbacks": total,
        "agreement_rate": agreement_rate,
        "agreed_count": agreed_count,
        "over_predicted": over_predicted,
        "under_predicted": under_predicted,
        "confusion_matrix": confusion_matrix,
        "gradcam_utility": gradcam_utility_counts,
        "lesion_frequencies": lesion_frequencies,
        "retraining_candidates_count": len(retraining_candidates),
        "retraining_export_path": retraining_export_path
    }


def seed_demo_doctor_feedbacks(output_dir: str = "outputs/doctor_feedback"):
    """
    Populates sample clinician reviews to demonstrate analysis capabilities.
    """
    demo_samples = [
        {
            "patient_id": "P-101-RAMESH",
            "doctor_name": "Not specified",
            "specialization": "Medical Officer (MBBS)",
            "phc_facility": "PHC Tele-Ophthalmology Centre",
            "ai_grade": 1,
            "doctor_grade": 1,
            "agreement_status": "Agree with AI",
            "gradcam_utility": "Accurately Localized True Lesions",
            "reported_lesions": ["Microaneurysms"],
            "improvement_notes": "Good early detection of subtle temporal microaneurysms.",
            "include_in_retraining": False
        },
        {
            "patient_id": "P-102-SUNITA",
            "doctor_name": "Dr. Rajesh Varma",
            "specialization": "Consultant Ophthalmologist",
            "phc_facility": "District Hospital Eye OPD",
            "ai_grade": 1,
            "doctor_grade": 2,
            "agreement_status": "Under-predicted by AI",
            "gradcam_utility": "Partially Useful",
            "reported_lesions": ["Microaneurysms", "Hard Exudates", "Blot Hemorrhages"],
            "improvement_notes": "Hard exudates near superior arcade were missed by model. Need better sensitivity for lipid deposits.",
            "include_in_retraining": True
        },
        {
            "patient_id": "P-103-MOHAMMED",
            "doctor_name": "Dr. Meera Iyer",
            "specialization": "Vitreo-Retina Specialist",
            "phc_facility": "Regional Eye Institute",
            "ai_grade": 3,
            "doctor_grade": 3,
            "agreement_status": "Agree with AI",
            "gradcam_utility": "Accurately Localized True Lesions",
            "reported_lesions": ["Venous Beading", "IRMA", "Extensive Hemorrhages"],
            "improvement_notes": "Accurate 4:2:1 severe criteria identification. Excellent referral urgency flag.",
            "include_in_retraining": False
        },
        {
            "patient_id": "P-104-KAMLA",
            "doctor_name": "Not specified",
            "specialization": "Medical Officer (MBBS)",
            "phc_facility": "PHC Tele-Ophthalmology Centre",
            "ai_grade": 2,
            "doctor_grade": 1,
            "agreement_status": "Over-predicted by AI",
            "gradcam_utility": "Inaccurate / Focused on Artifact",
            "reported_lesions": ["Microaneurysms"],
            "improvement_notes": "Nuclear cataract artifact caused dark shading that model falsely flagged as blot hemorrhages.",
            "include_in_retraining": True
        }
    ]

    for sample in demo_samples:
        save_feedback(sample, output_dir=output_dir)

    print(f"[+] Successfully seeded {len(demo_samples)} realistic clinical feedback entries.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Clinician Feedback Analyzer & Active Learning Manager")
    parser.add_argument("--analyze", action="store_true", help="Analyze all registered doctor feedback")
    parser.add_argument("--demo", action="store_true", help="Seed demo feedback entries and run analysis")
    parser.add_argument("--dir", type=str, default="outputs/doctor_feedback", help="Feedback directory path")

    args = parser.parse_args()

    if args.demo:
        seed_demo_doctor_feedbacks(args.dir)
        analyze_doctor_feedback(args.dir)
    elif args.analyze:
        analyze_doctor_feedback(args.dir)
    else:
        # Default behavior: run analysis if feedbacks exist, otherwise show demo
        res = analyze_doctor_feedback(args.dir)
        if res.get("total_feedbacks", 0) == 0:
            print("[*] No existing feedback found. Seeding demo cases to demonstrate analysis capabilities...\n")
            seed_demo_doctor_feedbacks(args.dir)
            analyze_doctor_feedback(args.dir)

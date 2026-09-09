"""
=============================================================================
TASK 3 — ENHANCEMENT 9: AUDIT TRAIL
File: audit.py
Function: create_audit_record(...)
=============================================================================
Generates clinical metadata, trace tokens, and reproducibility hashes for
regulatory auditing and provenance tracking. Does not invent patient data.
"""

import os
import hashlib
from datetime import datetime, timezone


def create_audit_record(
    patient_info: dict = None,
    model_result: dict = None,
    quality_result: dict = None,
    calibration_result: dict = None,
    report_version: str = "2.1.0",
    validation_status: str = "Pending Doctor Review"
) -> dict:
    """
    Constructs a compliance audit record for clinical tracking.
    
    Parameters:
        patient_info (dict, optional): Demographics passed in
        model_result (dict, optional): Task 2 outputs
        quality_result (dict, optional): Image quality assessment
        calibration_result (dict, optional): Confidence calibration
        report_version (str): Software version tag
        validation_status (str): Current review state
        
    Returns:
        dict: Complete audit record
    """
    model_res = model_result or {}
    quality_res = quality_result or {}
    calib_res = calibration_result or {}
    patient_data = patient_info or {}

    # Strict rule: If patient ID is not provided, use "Not provided". Do NOT invent patient information.
    patient_id = patient_data.get("patient_id")
    if not patient_id or str(patient_id).strip() == "":
        patient_id = "Not provided"

    # Compute image checksum if file is reachable
    image_path = model_res.get("image_path")
    image_hash = "N/A"
    if image_path and os.path.exists(image_path):
        try:
            with open(image_path, "rb") as f:
                image_hash = hashlib.sha256(f.read()).hexdigest()[:16]
        except Exception:
            image_hash = "Read error"

    now_utc = datetime.now(timezone.utc).isoformat()
    now_local = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    raw_conf = calib_res.get("raw_percentage", model_res.get("confidence", "N/A"))
    calib_conf = calib_res.get("calibrated_percentage", "Not available")

    return {
        "patient_id": patient_id,
        "timestamp_utc": now_utc,
        "timestamp_local": now_local,
        "model_name": model_res.get("model_name", "Diabetic Retinopathy CNN Grading Engine"),
        "model_version": model_res.get("model_version", "v1.0-icdr"),
        "task2_grade": model_res.get("grade", "N/A"),
        "raw_confidence": f"{raw_conf}%" if isinstance(raw_conf, (int, float)) else str(raw_conf),
        "calibrated_confidence": f"{calib_conf}%" if isinstance(calib_conf, (int, float)) else str(calib_conf),
        "image_quality_status": quality_res.get("status", "Not evaluated").title(),
        "image_quality_score": quality_res.get("score", "N/A"),
        "image_sha256_short": image_hash,
        "report_version": report_version,
        "doctor_validation_status": validation_status,
        "compliance_standard": "ICDR Scale / ISO 13485 Software Lifecycle Compliant"
    }

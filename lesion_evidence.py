"""
=============================================================================
TASK 3 — ENHANCEMENT 3: LESION EVIDENCE
File: lesion_evidence.py
Function: generate_lesion_evidence(lesions, image_path, output_dir="outputs")
=============================================================================
Parses, aggregates, and visualizes lesion findings reported by Task 2.
Strictly avoids inventing bounding box coordinates when spatial labels are missing.
"""

import os
import cv2
import numpy as np


def generate_lesion_evidence(lesions, image_path: str, output_dir: str = "outputs") -> dict:
    """
    Constructs structured clinical evidence from detected lesions.
    
    Parameters:
        lesions (list or dict): Detected lesions from Task 2
        image_path (str): Path to fundus image
        output_dir (str): Folder to store annotated visuals
        
    Returns:
        dict: {
            "has_lesions": bool,
            "has_coordinates": bool,
            "annotated_image": str or None,
            "findings": list of dict,
            "evidence_chain": str,
            "message": str
        }
    """
    os.makedirs(output_dir, exist_ok=True)
    findings = []
    has_coordinates = False
    
    # 1. Standardize lesion representation into structured findings
    if isinstance(lesions, list):
        # Format: ["microaneurysm", "hemorrhage"]
        for item in lesions:
            if isinstance(item, str):
                name = item.strip().lower()
                findings.append({
                    "type": name.title(),
                    "count": "Present",
                    "confidence": "AI Detected",
                    "coordinates": [],
                    "status": "AI Finding (Pending Doctor Confirmation)"
                })
            elif isinstance(item, dict):
                findings.append({
                    "type": item.get("type", "Unknown Lesion").title(),
                    "count": item.get("count", "Present"),
                    "confidence": f"{int(item['confidence'] * 100)}%" if "confidence" in item else "AI Detected",
                    "coordinates": item.get("coordinates", item.get("bbox", [])),
                    "status": "AI Finding (Pending Doctor Confirmation)"
                })
    elif isinstance(lesions, dict):
        # Format: {"microaneurysm": {"count": 8, "confidence": 0.91, "boxes": [...]}} or {"microaneurysm": 5}
        for name, data in lesions.items():
            if isinstance(data, dict):
                coords = data.get("coordinates", data.get("boxes", data.get("bbox", [])))
                conf_val = data.get("confidence")
                conf_str = f"{int(conf_val * 100)}%" if isinstance(conf_val, (int, float)) and conf_val <= 1.0 else str(conf_val or "AI Detected")
                findings.append({
                    "type": name.title(),
                    "count": data.get("count", 1),
                    "confidence": conf_str,
                    "coordinates": coords,
                    "status": "AI Finding (Pending Doctor Confirmation)"
                })
            elif isinstance(data, (int, float)):
                findings.append({
                    "type": name.title(),
                    "count": int(data),
                    "confidence": "AI Detected",
                    "coordinates": [],
                    "status": "AI Finding (Pending Doctor Confirmation)"
                })
            elif isinstance(data, str):
                findings.append({
                    "type": name.title(),
                    "count": data,
                    "confidence": "AI Detected",
                    "coordinates": [],
                    "status": "AI Finding (Pending Doctor Confirmation)"
                })

    # Check for actual coordinates
    for f in findings:
        if f.get("coordinates") and len(f["coordinates"]) > 0:
            has_coordinates = True
            break

    # 2. Annotation check (Strict Anti-Fabrication Rule)
    annotated_image_path = None
    if has_coordinates and image_path and os.path.exists(image_path):
        img = cv2.imread(image_path)
        if img is not None:
            for f in findings:
                coords = f.get("coordinates", [])
                label = f["type"]
                for box in coords:
                    if len(box) == 4:
                        x1, y1, x2, y2 = map(int, box)
                        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 255), 2)
                        cv2.putText(img, label, (x1, max(15, y1 - 5)),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 255, 255), 1, cv2.LINE_AA)
            annotated_image_path = os.path.join(output_dir, "lesion_evidence.png")
            cv2.imwrite(annotated_image_path, img)

    # 3. Evidence Chain Text
    has_lesions = len(findings) > 0
    if has_lesions:
        lesion_names = ", ".join([f["type"] for f in findings])
        evidence_chain = (
            f"Detected Evidence ({len(findings)} lesion classes) → "
            f"Pathology Identified ({lesion_names}) → "
            f"Task 2 DR Grade Decision"
        )
        msg = f"Identified {len(findings)} lesion category(ies). "
        if not has_coordinates:
            msg += "Spatial bounding coordinates were not provided by Task 2; tabular statistics reported without spatial fabrication."
    else:
        evidence_chain = "Lesion-level detection unavailable from Task 2 model."
        msg = "Lesion-level detection unavailable from Task 2 model."

    return {
        "has_lesions": has_lesions,
        "has_coordinates": has_coordinates,
        "annotated_image": annotated_image_path,
        "findings": findings,
        "evidence_chain": evidence_chain,
        "message": msg
    }

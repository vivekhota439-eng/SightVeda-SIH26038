"""
=============================================================================
TASK 3 — ENHANCEMENT 1: IMAGE QUALITY GATE
File: quality.py
Function: assess_image_quality(image_path)
=============================================================================
Evaluates fundus image quality (sharpness, exposure, contrast, resolution)
before report generation to ensure diagnostic reliability.
"""

import os
import cv2
import numpy as np


def assess_image_quality(image_path: str) -> dict:
    """
    Assesses the diagnostic quality of a retinal fundus image.
    
    Parameters:
        image_path (str): Path to input retinal photograph
        
    Returns:
        dict: {
            "status": "good" | "borderline" | "poor",
            "score": float (0.0 to 1.0),
            "is_reliable": bool,
            "message": str,
            "metrics": dict
        }
    """
    default_breakdown = {
        "laplacian_focus_variance": 0.0,
        "laplacian_focus_status": "Blurry / Defocused",
        "exposure_mean_intensity": 0.0,
        "exposure_uniformity_status": "Severe Underexposure",
        "retinal_contrast_std": 0.0,
        "media_opacity_cataract": "Inconclusive (Image Inaccessible)"
    }

    if not image_path or not os.path.exists(image_path):
        msg = f"Image file not found or inaccessible: {image_path}. Please provide a valid fundus image."
        return {
            "status": "poor",
            "score": 0.0,
            "is_reliable": False,
            "message": msg,
            "detailed_status": msg,
            "breakdown": default_breakdown,
            "metrics": {
                "resolution": (0, 0),
                "sharpness": 0.0,
                "brightness": 0.0,
                "contrast": 0.0
            }
        }

    # Load image
    img = cv2.imread(image_path)
    if img is None:
        msg = "Unable to decode image file. File may be corrupted or in an unsupported format."
        return {
            "status": "poor",
            "score": 0.0,
            "is_reliable": False,
            "message": msg,
            "detailed_status": msg,
            "breakdown": default_breakdown,
            "metrics": {
                "resolution": (0, 0),
                "sharpness": 0.0,
                "brightness": 0.0,
                "contrast": 0.0
            }
        }

    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Mask out surrounding black background typical of fundus cameras
    # Only evaluate pixels within the circular retinal field (intensity > 15)
    retina_mask = gray > 15
    retina_pixels = gray[retina_mask] if np.any(retina_mask) else gray.flatten()

    # 1. Sharpness Metric (Variance of Laplacian)
    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    # 2. Exposure / Illumination Metric (Mean of retinal pixels)
    brightness = float(np.mean(retina_pixels))

    # 3. Contrast Metric (Standard deviation of retinal pixels)
    contrast = float(np.std(retina_pixels))

    # Quality scoring logic
    issues = []
    
    # Sharpness checks (defocus/motion blur)
    if sharpness < 50.0:
        sharpness_score = 0.3
        issues.append("Significant blur detected; fine retinal vessels and microaneurysms may be obscured.")
    elif sharpness < 100.0:
        sharpness_score = 0.7
        issues.append("Moderate softness in image focus.")
    else:
        sharpness_score = 1.0

    # Illumination checks (underexposure / overexposure / flash glare)
    if brightness < 40.0:
        brightness_score = 0.3
        issues.append("Severe underexposure; dark retinal field.")
    elif brightness > 215.0:
        brightness_score = 0.3
        issues.append("Severe overexposure / flash glare.")
    elif brightness < 60.0 or brightness > 190.0:
        brightness_score = 0.7
        issues.append("Suboptimal lighting exposure.")
    else:
        brightness_score = 1.0

    # Contrast checks
    if contrast < 25.0:
        contrast_score = 0.4
        issues.append("Low tonal contrast across retinal layers.")
    elif contrast < 40.0:
        contrast_score = 0.7
    else:
        contrast_score = 1.0

    # Resolution check
    if min(w, h) < 256:
        resolution_score = 0.2
        issues.append(f"Image resolution ({w}x{h}) is below clinical minimum (256x256).")
    elif min(w, h) < 512:
        resolution_score = 0.7
    else:
        resolution_score = 1.0

    # Weighted aggregate score
    overall_score = (
        sharpness_score * 0.40 +
        brightness_score * 0.25 +
        contrast_score * 0.20 +
        resolution_score * 0.15
    )
    overall_score = round(float(overall_score), 2)

    # Categorization
    if overall_score >= 0.80 and len(issues) == 0:
        status = "good"
        is_reliable = True
        message = "Image quality is sufficient for screening. Clear view of retinal vessels and macula."
    elif overall_score >= 0.55:
        status = "borderline"
        is_reliable = True
        message = "Image quality is borderline: " + " ".join(issues) + " Proceed with caution during review."
    else:
        status = "poor"
        is_reliable = False
        message = "Poor image quality: " + " ".join(issues) + " Recapturing the fundus image is strongly recommended before clinical action."

    # Media opacity / cataract evaluation
    if sharpness >= 80 and contrast >= 35 and 60 <= brightness <= 190:
        media_opacity = "Clear Ocular Media (No significant anterior haze)"
    elif sharpness < 60 and contrast < 30:
        media_opacity = "Possible Media Haze / Co-existing Cataract Artifact"
    else:
        media_opacity = "Mild Optical Scattering Detected"

    sharpness_status = "Optimal Focus (Laplacian Var > 100)" if sharpness >= 100 else ("Soft Focus (Laplacian Var 50-100)" if sharpness >= 50 else "Defocus / Motion Blur Detected")
    exposure_status = "Uniform Illumination (Within Triage Limits)" if 60 <= brightness <= 190 else ("Underexposed / Dark Retinal Field" if brightness < 60 else "Overexposed / Flash Glare")
    contrast_status = "High Microvascular Definition (Std >= 40)" if contrast >= 40 else "Low Layer Contrast (Std < 40)"

    breakdown = {
        "laplacian_focus_variance": round(sharpness, 1),
        "laplacian_focus_status": sharpness_status,
        "exposure_mean_intensity": round(brightness, 1),
        "exposure_uniformity_status": exposure_status,
        "retinal_contrast_std": round(contrast, 1),
        "media_opacity_cataract": media_opacity
    }

    return {
        "status": status,
        "score": overall_score,
        "is_reliable": is_reliable,
        "message": message,
        "detailed_status": message,
        "breakdown": breakdown,
        "metrics": {
            "resolution": f"{w} x {h}",
            "sharpness": round(sharpness, 1),
            "sharpness_status": sharpness_status,
            "brightness": round(brightness, 1),
            "exposure_status": exposure_status,
            "contrast": round(contrast, 1),
            "contrast_status": contrast_status,
            "media_opacity": media_opacity
        }
    }

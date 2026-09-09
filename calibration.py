"""
=============================================================================
TASK 3 — ENHANCEMENT 4: CONFIDENCE CALIBRATION
File: calibration.py
Function: calibrate_confidence(raw_confidence, calibrator=None)
=============================================================================
Calibrates model probability scores using empirical post-processing methods
(Temperature Scaling, Platt Scaling, Isotonic Regression).
Strictly prevents fabricating synthetic calibrated scores when calibration models are missing.
"""


def calibrate_confidence(raw_confidence: float, calibrator=None) -> dict:
    """
    Calibrates raw neural network confidence output.
    
    Parameters:
        raw_confidence (float): Raw softmax/sigmoid output from Task 2 (0.0 - 1.0)
        calibrator (object or callable, optional): Trained calibrator
            (e.g., Platt scaling logistic regressor, Temperature scaling parameter, or IsotonicRegression model)
            
    Returns:
        dict: {
            "status": "calibrated" | "unavailable",
            "raw_confidence": float,
            "raw_percentage": float,
            "calibrated_confidence": float or None,
            "calibrated_percentage": float or None,
            "display_text": str,
            "method": str,
            "note": str
        }
    """
    # Sanitize raw confidence
    try:
        raw_conf = float(raw_confidence)
        # Clinical AI Safety Rule: In healthcare screening, an AI model must NEVER claim 100% certainty.
        # Overconfident softmax scores (e.g. 1.0 or 0.999) are safely capped to realistic clinical screening limits (max 98.5% - 99.0%).
        raw_conf = max(0.01, min(0.99, raw_conf))
    except (TypeError, ValueError):
        raw_conf = 0.50

    raw_pct = round(raw_conf * 100, 1)

    # Strict Anti-Fabrication Rule:
    # If no real calibrator is supplied, do NOT invent a number.
    if calibrator is None:
        return {
            "status": "unavailable",
            "raw_confidence": raw_conf,
            "raw_percentage": raw_pct,
            "calibrated_confidence": None,
            "calibrated_percentage": None,
            "display_text": "Calibration unavailable — suitable validation data not provided.",
            "method": "Calibration unavailable — suitable validation data not provided.",
            "note": "Calibration unavailable — suitable validation data not provided."
        }

    try:
        # 1. Temperature Scaling: if calibrator is a float/int temperature T > 0
        if isinstance(calibrator, (int, float)):
            t = float(calibrator)
            if t > 0:
                # Logit-based temperature adjustment: logit = log(p / (1-p))
                import math
                eps = 1e-7
                p = max(eps, min(1.0 - eps, raw_conf))
                logit = math.log(p / (1.0 - p))
                scaled_logit = logit / t
                calibrated = 1.0 / (1.0 + math.exp(-scaled_logit))
                method_name = f"Temperature Scaling (T={t:.2f})"
            else:
                raise ValueError("Temperature must be positive.")
        # 2. Scikit-learn style Calibrator (Platt Scaling LogisticRegression or IsotonicRegression)
        elif hasattr(calibrator, "predict_proba"):
            import numpy as np
            probs = calibrator.predict_proba(np.array([[raw_conf]]))
            calibrated = float(probs[0, 1]) if probs.shape[1] > 1 else float(probs[0, 0])
            method_name = getattr(calibrator, "__class__", type(calibrator)).__name__
        elif hasattr(calibrator, "predict"):
            import numpy as np
            calibrated = float(calibrator.predict(np.array([[raw_conf]]))[0])
            method_name = getattr(calibrator, "__class__", type(calibrator)).__name__
        # 3. Callable custom function
        elif callable(calibrator):
            calibrated = float(calibrator(raw_conf))
            method_name = "Custom Callable Calibrator"
        else:
            raise TypeError("Unsupported calibrator type.")

        calibrated = max(0.01, min(0.99, calibrated))
        cal_pct = round(calibrated * 100, 1)

        return {
            "status": "calibrated",
            "raw_confidence": raw_conf,
            "raw_percentage": raw_pct,
            "calibrated_confidence": round(calibrated, 4),
            "calibrated_percentage": cal_pct,
            "display_text": f"Raw: {raw_pct}% | Calibrated: {cal_pct}%",
            "method": method_name,
            "note": f"Confidence empirically calibrated via {method_name}."
        }

    except Exception as e:
        return {
            "status": "unavailable",
            "raw_confidence": raw_conf,
            "raw_percentage": raw_pct,
            "calibrated_confidence": None,
            "calibrated_percentage": None,
            "display_text": "Calibration: Not available (Error during calibration)",
            "method": "Failed",
            "note": f"Calibration failed: {str(e)}. Displaying uncalibrated raw model confidence."
        }

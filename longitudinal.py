"""
=============================================================================
TASK 3 — ENHANCEMENT 5: LONGITUDINAL PATIENT TRACKING
File: longitudinal.py
Function: compare_longitudinal_history(current_grade, patient_history=None, output_dir="outputs")
=============================================================================
Tracks progression or regression across historical patient screenings.
Strictly avoids fabricating prior visit data. Accounts for imaging differences.
"""

import os
from datetime import datetime


def compare_longitudinal_history(current_grade: int, current_confidence: float = None, patient_history: list = None, output_dir: str = "outputs") -> dict:
    """
    Compares current screening findings with previous patient examination records.
    
    Parameters:
        current_grade (int): AI predicted ICDR grade (0-4)
        current_confidence (float, optional): Current model confidence
        patient_history (list of dict, optional): List of prior records, e.g.:
            [{"date": "2024-01-15", "grade": 1, "confidence": 0.89, "quality": "good"}, ...]
        output_dir (str): Directory for output visual trend graphs
        
    Returns:
        dict: {
            "available": bool,
            "message": str,
            "trend": "baseline" | "progressed" | "stable" | "regressed",
            "grade_change": int or None,
            "graph_path": str or None,
            "history_table": list of dict,
            "limitations": list of str
        }
    """
    os.makedirs(output_dir, exist_ok=True)
    
    current_grade = int(max(0, min(4, current_grade)))
    current_conf_str = f"{int(current_confidence * 100)}%" if current_confidence is not None else "N/A"
    today_str = datetime.now().strftime("%Y-%m-%d")

    # Strict Anti-Fabrication Rule:
    # If no prior history is passed, do NOT invent previous visits.
    if not patient_history or len(patient_history) == 0:
        return {
            "available": False,
            "message": "Longitudinal comparison unavailable. This is the patient's baseline assessment.",
            "trend": "baseline",
            "grade_change": None,
            "graph_path": None,
            "history_table": [{
                "date": f"{today_str} (Current)",
                "grade": f"Grade {current_grade}",
                "confidence": current_conf_str,
                "status": "Baseline Assessment"
            }],
            "limitations": [
                "No prior historical imaging records exist in patient profile.",
                "Clinical progression cannot be established without baseline comparisons."
            ]
        }

    # Sort history chronologically
    sorted_history = sorted(patient_history, key=lambda x: str(x.get("date", "")))
    last_visit = sorted_history[-1]
    prev_grade = int(last_visit.get("grade", current_grade))
    grade_delta = current_grade - prev_grade

    if grade_delta > 0:
        trend = "progressed"
        trend_label = f"Possible disease progression detected (Grade {prev_grade} → Grade {current_grade}). Escalation advised."
    elif grade_delta < 0:
        trend = "regressed"
        trend_label = f"Improvement / regression observed (Grade {prev_grade} → Grade {current_grade})."
    else:
        trend = "stable"
        trend_label = f"Condition appears stable at Grade {current_grade}."

    # Build chronological table including current visit
    history_table = []
    dates = []
    grades = []

    for visit in sorted_history:
        d = str(visit.get("date", "Unknown Date"))
        g = int(visit.get("grade", 0))
        c = visit.get("confidence")
        c_str = f"{int(c * 100)}%" if isinstance(c, (int, float)) and c <= 1.0 else str(c or "N/A")
        history_table.append({
            "date": d,
            "grade": f"Grade {g}",
            "confidence": c_str,
            "status": "Historical Record"
        })
        dates.append(d)
        grades.append(g)

    # Append current visit
    history_table.append({
        "date": f"{today_str} (Current)",
        "grade": f"Grade {current_grade}",
        "confidence": current_conf_str,
        "status": f"Current ({trend.title()})"
    })
    dates.append("Current")
    grades.append(current_grade)

    # 3. Generate Trend Graph (Matplotlib if available, otherwise pure SVG fallback)
    graph_path = os.path.join(output_dir, "longitudinal_trend.png")
    graph_generated = False

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        plt.figure(figsize=(6, 3.2), dpi=120)
        plt.plot(range(len(grades)), grades, marker='o', color='#2563eb', linewidth=2.5, markersize=8)
        plt.title("Diabetic Retinopathy Longitudinal Grade Progression", fontsize=11, fontweight="bold", pad=10)
        plt.xticks(range(len(dates)), dates, fontsize=9)
        plt.yticks([0, 1, 2, 3, 4], ["0: None", "1: Mild", "2: Mod", "3: Sev", "4: PDR"], fontsize=9)
        plt.ylim(-0.5, 4.5)
        plt.grid(True, linestyle="--", alpha=0.5)
        plt.tight_layout()
        plt.savefig(graph_path)
        plt.close()
        graph_generated = True
    except Exception:
        # Fallback if matplotlib is unavailable or fails in headless environment
        graph_path = None

    # Limitations to document
    limitations = [
        "Variations in pupil dilation, camera optics, or illumination between visits can influence microvascular visibility.",
        "Longitudinal comparison is rule-based and should be correlated with comprehensive dilated clinical exams."
    ]
    if any(v.get("quality") == "poor" for v in sorted_history):
        limitations.append("Warning: One or more previous visits had suboptimal image quality.")

    return {
        "available": True,
        "message": trend_label,
        "trend": trend,
        "grade_change": grade_delta,
        "graph_path": graph_path if graph_generated else None,
        "history_table": history_table,
        "limitations": limitations
    }

"""
=============================================================================
TASK 3 — ENHANCEMENT 8: DOCTOR-IN-THE-LOOP VALIDATION
File: doctor_validation.py
Function: create_doctor_validation_section(ai_grade, current_status="Pending Doctor Review")
=============================================================================
Renders doctor-in-the-loop review controls.
Enforces strict distinction between AI-generated findings and certified clinical sign-offs.
Default status is unconditionally 'Pending Doctor Review'.
"""


def create_doctor_validation_section(ai_grade: int, current_status: str = "Pending Doctor Review", doctor_info: dict = None) -> dict:
    """
    Constructs data and visual state for physician verification.
    
    Parameters:
        ai_grade (int): AI predicted grade (0-4)
        current_status (str): Validation status ('Pending Doctor Review', 'Approved', 'Modified', 'Rejected')
        doctor_info (dict, optional): Details if physician has already reviewed
        
    Returns:
        dict: Structured verification dictionary for report rendering
    """
    valid_statuses = [
        "Pending Doctor Review",
        "Approved by Ophthalmologist",
        "Modified by Ophthalmologist",
        "Rejected / Re-examination Required"
    ]
    
    status = current_status if current_status in valid_statuses else "Pending Doctor Review"
    is_pending = (status == "Pending Doctor Review")

    info = doctor_info or {}
    doctor_name = info.get("name", "______________________________")
    reg_number = info.get("reg_number", "____________________")
    review_date = info.get("review_date", "____________________")
    comments = info.get("comments", "")
    final_grade = info.get("doctor_grade", None)

    return {
        "status": status,
        "is_pending": is_pending,
        "ai_grade": ai_grade,
        "doctor_grade": final_grade,
        "doctor_name": doctor_name,
        "reg_number": reg_number,
        "review_date": review_date,
        "doctor_comments": comments,
        "review_options": [
            {"label": "Agree with AI Assessment", "value": "agree", "checked": status == "Approved by Ophthalmologist"},
            {"label": "Modify Grade", "value": "modify", "checked": status == "Modified by Ophthalmologist"},
            {"label": "Reject / Recommend In-Person Dilation", "value": "reject", "checked": status == "Rejected / Re-examination Required"}
        ],
        "disclaimer": (
            "Clinical Protocol: This automated report constitutes assistive screening data only. "
            "A diagnosis is only finalized upon physical or tele-ophthalmic validation and sign-off "
            "by a licensed eye care practitioner."
        )
    }

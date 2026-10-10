def explain(level, indicators):
    summary = {
        "Safe": "No substantial indicators were found by the available checks.",
        "Suspicious": "Potentially risky indicators deserve independent verification.",
        "High Risk": "Strong indicators suggest a possible scam or phishing attempt.",
    }[level]
    actions = [
        "Verify the sender through a contact method you already trust.",
        "Never share an OTP, password or PIN. Do not install remote access tools on request.",
    ]
    if level != "Safe":
        actions.insert(0, "Pause before paying, replying or opening links.")
    return {
        "summary": summary,
        "recommendations": actions,
        "score_explanation": "Each distinct indicator contributes its displayed points, "
        "capped at 100. An optional uncalibrated model signal uses the higher score, "
        "rather than adding overlapping evidence.",
        "indicators": indicators,
    }

def risk_level(score, safe=30, high=70):
    if score <= safe:
        return "Safe"
    if score <= high:
        return "Suspicious"
    return "High Risk"


def score_signals(indicators, model_signal=None):
    # Correlated repeated evidence contributes once per rule family.
    unique = {}
    for item in indicators:
        if item["code"] not in unique or item["points"] > unique[item["code"]]["points"]:
            unique[item["code"]] = item
    total = min(100, sum(item["points"] for item in unique.values()))
    if model_signal is not None:
        # Model overlaps text rules; max avoids adding the same evidence twice.
        total = max(total, round(max(0, min(1, model_signal)) * 80))
    return total, list(unique.values())

from functools import lru_cache

from app.core.config import settings
from app.detectors.rules import (
    RULE_VERSION,
    email_indicators,
    evidence,
    normalize,
    text_indicators,
    url_indicators,
)
from app.explanations import explain
from app.ml.inference import Model
from app.scoring import risk_level, score_signals
from app.services.providers import reputation


@lru_cache
def model():
    return Model(settings().model_path)


def detect(request):
    cfg = settings()
    text = normalize(request.content)
    signal = None
    provider = {"status": "not_requested", "listed": None}
    if request.channel == "url":
        indicators, canonical = url_indicators(text)
        provider = {"status": "not_consented", "listed": None}
        if request.allow_external_reputation:
            if not any(i["code"] == "url_private" for i in indicators):
                provider = reputation(canonical)
            else:
                provider = {"status": "internal_destination_skipped", "listed": None}
        if provider["listed"]:
            indicators.append(
                evidence(
                    "reputation",
                    "Listed by reputation provider",
                    85,
                    "Configured provider returned a known-threat match.",
                )
            )
    else:
        indicators = text_indicators(request.subject + " " + text)
        if request.channel == "email":
            indicators += email_indicators(
                request.sender, request.reply_to, request.attachment_names
            )
        if request.channel == "sms":
            signal = model().predict(text)
    score, indicators = score_signals(indicators, signal)
    level = risk_level(score, cfg.safe_threshold, cfg.high_threshold)
    limits = [
        "Scores are indicators, not proof of fraud or safety.",
        "English contextual rules may miss unfamiliar or regional-language scams.",
        "No target website, attachment, sender identity or speaker was authenticated.",
        "Evidence descriptions omit raw private content from stored history.",
    ]
    if model().version is None:
        limits.append("Rule baseline only: no trained model loaded; accuracy is not validated.")
    else:
        limits.append("Model signal is uncalibrated and is not a probability of fraud.")
    if request.channel == "url":
        limits.append("No DNS, certificate, redirect or domain-age checks were performed.")
        if provider["status"] != "available":
            limits.append(
                "Reputation service is not available; only lexical analysis was performed."
            )
    if request.channel == "email":
        limits.append("SPF, DKIM and DMARC have not been verified.")
    if request.channel in {"call", "voice"}:
        limits.append(
            "Content analysis only; no deepfake, speaker identity or phone reputation check."
        )
    return {
        "score": score,
        "risk_level": level,
        **explain(level, indicators),
        "rule_version": RULE_VERSION,
        "model_version": model().version,
        "model_signal": signal,
        "reputation": provider,
        "limitations": limits,
    }

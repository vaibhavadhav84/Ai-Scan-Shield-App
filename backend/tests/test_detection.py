import pytest

from app.detectors.rules import normalize, parse_url, text_indicators, url_indicators
from app.schemas import ScanInput
from app.scoring import risk_level, score_signals
from app.services.detection import detect


@pytest.mark.parametrize(
    "score,level",
    [
        (0, "Safe"),
        (30, "Safe"),
        (31, "Suspicious"),
        (70, "Suspicious"),
        (71, "High Risk"),
        (100, "High Risk"),
    ],
)
def test_boundaries(score, level):
    assert risk_level(score) == level


@pytest.mark.parametrize(
    "text",
    [
        "Your OTP is 123456. Never share this code.",
        "Do not send your password to anyone.",
        "Can you pay for lunch tomorrow?",
        "The job offer meeting starts at 10.",
        "Meet me at the library.",
    ],
)
def test_contextual_benign(text):
    assert detect(ScanInput(channel="sms", content=text))["risk_level"] == "Safe"


def test_strong_scam():
    result = detect(
        ScanInput(
            channel="sms",
            content="Urgent bank warning. Share your OTP "
            "immediately or your account will be blocked. Pay a processing fee now.",
        )
    )
    assert result["risk_level"] == "High Risk"
    assert result["score"] <= 100
    assert {i["code"] for i in result["indicators"]} >= {"credential_request", "coercive_payment"}
    assert result["model_version"] is None


def test_deduplicated_signals():
    items = text_indicators("Send your OTP. Send your OTP.")
    score, unique = score_signals(items + items)
    assert score == 50
    assert len(unique) == 1


@pytest.mark.parametrize(
    "url",
    [
        "file:///etc/passwd",
        "javascript:alert(1)",
        "http://",
        "https://good.test\\@bad.test",
        "https://%31%32.test",
        "https://a.test:99999",
        "https://bad host.test",
    ],
)
def test_invalid_urls(url):
    with pytest.raises(ValueError):
        parse_url(url)


@pytest.mark.parametrize(
    "url",
    [
        "http://127.0.0.1/",
        "http://169.254.169.254/latest/meta-data/",
        "https://[::1]/",
        "https://localhost/",
        "http://10.0.0.1/",
    ],
)
def test_internal_destination_never_fetched(url, monkeypatch):
    monkeypatch.setattr("httpx.get", lambda *a, **k: pytest.fail("Target fetched"))
    signals, _ = url_indicators(url)
    assert "url_private" in {s["code"] for s in signals}


def test_email_metadata():
    result = detect(
        ScanInput(
            channel="email",
            content="See attached document.",
            sender="sender@example.com",
            reply_to="billing@different.example",
            attachment_names=["bill.docm"],
        )
    )
    assert result["score"] == 50
    assert "SPF, DKIM and DMARC have not been verified." in result["limitations"]


def test_unicode_preservation():
    assert "नमस्कार" in normalize("  नमस्कार\nworld  ")


def test_url_reputation_unavailable():
    result = detect(
        ScanInput(channel="url", content="https://example.com", allow_external_reputation=True)
    )
    assert result["reputation"]["status"] == "unconfigured"
    assert any("lexical" in limit for limit in result["limitations"])

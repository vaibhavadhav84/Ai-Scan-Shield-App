import io
import wave

import pytest
from fastapi import HTTPException

from app.core.config import Settings
from app.schemas import ScanInput, ScanResult
from app.services.detection import detect
from app.services.providers import validate_audio


def test_reputation_requires_consent_and_skips_internal(monkeypatch):
    monkeypatch.setattr(
        "app.services.detection.reputation", lambda value: pytest.fail("No consent")
    )
    result = detect(ScanInput(channel="url", content="https://example.com"))
    assert result["reputation"]["status"] == "not_consented"
    result = detect(
        ScanInput(channel="url", content="http://127.0.0.1", allow_external_reputation=True)
    )
    assert result["reputation"]["status"] == "internal_destination_skipped"


def test_startup_validation_hides_secrets():
    with pytest.raises(ValueError) as error:
        Settings(
            environment="production",
            database_url="sqlite:///test.db",
            smtp_password="secret-value-must-not-appear",
        )
    assert "secret-value-must-not-appear" not in str(error.value)


def test_noncommercial_acknowledgement():
    with pytest.raises(ValueError, match="noncommercial"):
        Settings(reputation_provider="google-safe-browsing", reputation_noncommercial_use=False)


def test_invalid_audio_truncation():
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as recording:
        recording.setnchannels(1)
        recording.setsampwidth(2)
        recording.setframerate(8000)
        recording.writeframes(b"\0" * 16000)
    with pytest.raises(HTTPException) as error:
        validate_audio(buffer.getvalue()[:-10])
    assert error.value.status_code == 422


def test_result_schema_rejects_invalid_score():
    value = detect(ScanInput(channel="sms", content="Meeting at 10."))
    with pytest.raises(ValueError):
        ScanResult(id="test", channel="sms", created_at=1, **{**value, "score": 101})

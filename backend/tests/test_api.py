import io
import time
import wave

from conftest import account
from sqlalchemy import select

from app.core.config import settings
from app.core.database import SessionLocal
from app.models import ActionToken, Alert, Feedback, Report, Scan, SessionToken, User
from app.security import digest

PREFIX = "/api/v1"


def submit(client, headers, content="Share your OTP immediately or pay a processing fee urgently."):
    response = client.post(
        f"{PREFIX}/scans", headers=headers, json={"channel": "sms", "content": content}
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_complete_scan_journey(client, headers):
    scan = submit(client, headers)
    assert scan["risk_level"] == "High Risk"
    assert client.get(f"{PREFIX}/scans/{scan['id']}", headers=headers).json()["id"] == scan["id"]
    assert client.get(f"{PREFIX}/scans", headers=headers).json()["total"] == 1
    assert (
        client.put(
            f"{PREFIX}/scans/{scan['id']}/feedback", headers=headers, json={"verdict": "correct"}
        ).status_code
        == 200
    )
    body = {"scan_id": scan["id"], "category": "credentials"}
    assert client.post(f"{PREFIX}/reports", headers=headers, json=body).status_code == 201
    assert client.post(f"{PREFIX}/reports", headers=headers, json=body).status_code == 409
    alert = client.get(f"{PREFIX}/alerts", headers=headers).json()["items"][0]
    assert client.patch(f"{PREFIX}/alerts/{alert['id']}/read", headers=headers).status_code == 200
    exported = client.get(f"{PREFIX}/users/me/export", headers=headers).json()
    assert len(exported["scans"]) == len(exported["reports"]) == 1
    assert "content" not in exported["scans"][0]
    assert "Share your OTP immediately or pay a processing fee urgently." not in str(exported)
    assert client.delete(f"{PREFIX}/scans/{scan['id']}", headers=headers).status_code == 200
    assert client.get(f"{PREFIX}/reports", headers=headers).json()["items"] == []
    with SessionLocal() as db:
        assert db.scalar(select(Feedback)) is None
        assert db.scalar(select(Alert)) is None


def test_cross_user_all_routes(client, headers):
    scan = submit(client, headers)
    other, _ = account(client, "other@example.com")
    for method, route, body in [
        ("GET", f"/scans/{scan['id']}", None),
        ("DELETE", f"/scans/{scan['id']}", None),
        ("PUT", f"/scans/{scan['id']}/feedback", {"verdict": "correct"}),
        ("POST", "/reports", {"scan_id": scan["id"], "category": "other"}),
    ]:
        assert client.request(method, PREFIX + route, headers=other, json=body).status_code == 404
    assert client.get(f"{PREFIX}/scans", headers=other).json()["total"] == 0
    assert client.get(f"{PREFIX}/admin/metrics", headers=other).status_code == 403


def test_refresh_rotates_and_logout_revokes(client):
    headers, tokens = account(client)
    refreshed = client.post(f"{PREFIX}/auth/refresh", json={"token": tokens["refresh_token"]})
    assert refreshed.status_code == 200
    assert client.get(f"{PREFIX}/users/me", headers=headers).status_code == 401
    assert (
        client.post(f"{PREFIX}/auth/refresh", json={"token": tokens["refresh_token"]}).status_code
        == 401
    )
    new = {"Authorization": "Bearer " + refreshed.json()["access_token"]}
    assert client.post(f"{PREFIX}/auth/logout", headers=new).status_code == 200
    assert client.get(f"{PREFIX}/users/me", headers=new).status_code == 401


def test_sessions_hashed_and_expired(client):
    headers, tokens = account(client)
    with SessionLocal() as db:
        session = db.scalar(select(SessionToken))
        assert session.access_hash != tokens["access_token"]
        assert session.access_hash == digest(tokens["access_token"])
        session.access_expires = time.time() - 1
        db.commit()
    assert client.get(f"{PREFIX}/users/me", headers=headers).status_code == 401


def test_verification_token_once(client):
    response = client.post(
        f"{PREFIX}/auth/register",
        json={"email": "verify@example.com", "password": "strong-test-password"},
    )
    token = response.json()["development_token"]
    assert (
        client.post(f"{PREFIX}/auth/verification/confirm", json={"token": token}).status_code == 200
    )
    assert (
        client.post(f"{PREFIX}/auth/verification/confirm", json={"token": token}).status_code == 400
    )


def test_password_reset_revokes(client, headers):
    token = "a-long-random-reset-token-for-tests"
    with SessionLocal() as db:
        user = db.scalar(select(User))
        db.add(
            ActionToken(
                token_hash=digest(token),
                user_id=user.id,
                purpose="reset",
                expires_at=time.time() + 500,
            )
        )
        db.commit()
    assert (
        client.post(
            f"{PREFIX}/auth/password/confirm",
            json={"token": token, "password": "new-password-strong"},
        ).status_code
        == 200
    )
    assert client.get(f"{PREFIX}/users/me", headers=headers).status_code == 401
    assert client.post(
        f"{PREFIX}/auth/password/request", json={"email": "tester@example.com"}
    ).json().keys() == {"message"}


def test_validation_redacts_secrets(client):
    response = client.post(
        f"{PREFIX}/auth/register", json={"email": "invalid", "password": "SECRET"}
    )
    assert response.status_code == 422
    assert "SECRET" not in response.text


def test_preferences_and_retention(client, headers):
    assert (
        client.patch(
            f"{PREFIX}/users/me",
            headers=headers,
            json={"display_name": "", "alerts_enabled": False, "retention_days": 1},
        ).status_code
        == 200
    )
    scan = submit(client, headers)
    assert client.get(f"{PREFIX}/alerts", headers=headers).json()["items"] == []
    with SessionLocal() as db:
        item = db.get(Scan, scan["id"])
        item.created_at = time.time() - 172800
        db.commit()
    assert client.get(f"{PREFIX}/scans", headers=headers).json()["total"] == 0


def test_account_cascade_deletion(client, headers):
    scan = submit(client, headers)
    client.post(
        f"{PREFIX}/reports", headers=headers, json={"scan_id": scan["id"], "category": "other"}
    )
    assert (
        client.request(
            "DELETE",
            f"{PREFIX}/users/me",
            headers=headers,
            json={"password": "test-password-strong"},
        ).status_code
        == 200
    )
    with SessionLocal() as db:
        for entity in [User, Scan, SessionToken, Report, Alert]:
            assert db.scalar(select(entity)) is None


def wav():
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(16000)
        audio.writeframes(b"\0" * 32000)
    return buffer.getvalue()


def test_voice_invalid_and_unconfigured(client, headers):
    response = client.post(
        f"{PREFIX}/scans/voice",
        headers=headers,
        files={"file": ("audio.wav", b"malicious executable", "audio/wav")},
    )
    assert response.status_code == 422
    response = client.post(
        f"{PREFIX}/scans/voice", headers=headers, files={"file": ("audio.wav", wav(), "audio/wav")}
    )
    assert response.status_code == 503
    assert "not configured" in response.json()["detail"]


def test_voice_transcript_not_stored(client, headers, monkeypatch):
    monkeypatch.setattr("app.api.scans.transcribe", lambda data: "Send your OTP immediately")
    response = client.post(
        f"{PREFIX}/scans/voice", headers=headers, files={"file": ("audio.wav", wav(), "audio/wav")}
    )
    assert response.status_code == 201
    assert response.json()["transcript"] == "Send your OTP immediately"
    saved = client.get(f"{PREFIX}/scans/{response.json()['id']}", headers=headers).json()
    assert "transcript" not in saved


def test_email_import_safe(client, headers):
    raw = (
        b"From: test@example.com\r\nSubject: Status\r\n"
        b"Content-Type: text/plain\r\n\r\nMeeting at 10."
    )
    assert (
        client.post(
            f"{PREFIX}/scans/email-file",
            headers=headers,
            files={"file": ("sample.eml", raw, "message/rfc822")},
        ).status_code
        == 201
    )
    assert (
        client.post(
            f"{PREFIX}/scans/email-file", headers=headers, files={"file": ("sample.exe", raw)}
        ).status_code
        == 422
    )


def test_rate_limit_and_body_cap(client, monkeypatch):
    monkeypatch.setattr(settings(), "auth_rate_limit", 2)
    for _ in range(2):
        assert (
            client.post(
                f"{PREFIX}/auth/login", json={"email": "none@example.com", "password": "x"}
            ).status_code
            == 401
        )
    assert (
        client.post(
            f"{PREFIX}/auth/login", json={"email": "none@example.com", "password": "x"}
        ).status_code
        == 429
    )
    assert client.post("/health", content=b"x" * (1024 * 1024 + 1)).status_code == 413


def test_reputation_failure(client, headers, monkeypatch):
    monkeypatch.setattr(
        "app.services.detection.reputation", lambda value: {"status": "unavailable", "listed": None}
    )
    result = client.post(
        f"{PREFIX}/scans",
        headers=headers,
        json={
            "channel": "url",
            "content": "https://example.com",
            "allow_external_reputation": True,
        },
    )
    assert result.status_code == 201
    assert result.json()["reputation"]["status"] == "unavailable"


def test_production_https_guard(client, monkeypatch):
    monkeypatch.setattr(settings(), "environment", "production")
    assert client.get("/health").status_code == 400

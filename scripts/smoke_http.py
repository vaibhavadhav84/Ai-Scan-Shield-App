"""Exercise a running development API over HTTP; delete the disposable account afterward."""

import uuid

import httpx

with httpx.Client(base_url="http://127.0.0.1:8000", timeout=15) as client:
    assert client.get("/health").json()["status"] == "ok"
    assert client.get("/ready").status_code == 200
    email = f"smoke-{uuid.uuid4().hex}@example.com"
    password = uuid.uuid4().hex + uuid.uuid4().hex
    registered = client.post(
        "/api/v1/auth/register", json={"email": email, "password": password}
    )
    registered.raise_for_status()
    verification = registered.json().get("development_token")
    if verification:
        client.post(
            "/api/v1/auth/verification/confirm", json={"token": verification}
        ).raise_for_status()
    tokens = client.post(
        "/api/v1/auth/login", json={"email": email, "password": password}
    )
    tokens.raise_for_status()
    client.headers["Authorization"] = "Bearer " + tokens.json()["access_token"]
    try:
        scan = client.post(
            "/api/v1/scans",
            json={
                "channel": "sms",
                "content": "Send your OTP immediately or your bank account will be blocked.",
            },
        )
        scan.raise_for_status()
        assert scan.json()["risk_level"] == "High Risk"
        sid = scan.json()["id"]
        client.put(
            f"/api/v1/scans/{sid}/feedback", json={"verdict": "correct"}
        ).raise_for_status()
        client.post(
            "/api/v1/reports", json={"scan_id": sid, "category": "credentials"}
        ).raise_for_status()
        assert client.get("/api/v1/scans").json()["total"] == 1
        client.delete(f"/api/v1/scans/{sid}").raise_for_status()
        assert client.get("/api/v1/scans").json()["total"] == 0
    finally:
        client.request(
            "DELETE", "/api/v1/users/me", json={"password": password}
        ).raise_for_status()
print(
    "HTTP health/readiness/register/verify/login/scan/history/feedback/report/delete passed; test account removed."
)

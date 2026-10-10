import os
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

database_path = Path(__file__).resolve().parent / f"test-{uuid.uuid4().hex}.db"
os.environ["ENVIRONMENT"] = "test"
os.environ["DATABASE_URL"] = f"sqlite:///{database_path.as_posix()}"
os.environ["AUTH_RATE_LIMIT"] = "1000"
os.environ["RATE_LIMIT"] = "1000"
os.environ["MODEL_PATH"] = ""

from app.core.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture
def client():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session", autouse=True)
def cleanup():
    yield
    engine.dispose()
    database_path.unlink(missing_ok=True)


def account(client, email="tester@example.com"):
    password = "test-password-strong"
    response = client.post("/api/v1/auth/register", json={"email": email, "password": password})
    assert response.status_code == 201, response.text
    tokens = client.post("/api/v1/auth/login", json={"email": email, "password": password}).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}, tokens


@pytest.fixture
def headers(client):
    return account(client)[0]

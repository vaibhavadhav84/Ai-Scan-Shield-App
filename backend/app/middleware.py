import hashlib
import json
import logging
import time

from sqlalchemy import delete
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app.core.config import settings
from app.core.database import SessionLocal
from app.models import RateBucket

logger = logging.getLogger("scan_shield")


class Boundaries:
    """ASGI request caps apply before multipart parsing; log no body, tokens or URL queries."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        path = scope["path"]
        cfg = settings()
        started = time.monotonic()

        async def reject(status, detail):
            await send(
                {
                    "type": "http.response.start",
                    "status": status,
                    "headers": [(b"content-type", b"application/json")],
                }
            )
            await send(
                {"type": "http.response.body", "body": json.dumps({"detail": detail}).encode()}
            )

        if cfg.environment == "production" and scope["scheme"] != "https":
            return await reject(400, "HTTPS required")
        if path.startswith("/api/"):
            host = (scope.get("client") or ("unknown",))[0]
            group = "auth" if path.startswith("/api/v1/auth/") else "api"
            key = hashlib.sha256(f"{host}:{group}".encode()).hexdigest()
            window = int(time.time() // 60)
            limit = cfg.auth_rate_limit if group == "auth" else cfg.rate_limit
            with SessionLocal() as db:
                insert = sqlite_insert if db.bind.dialect.name == "sqlite" else pg_insert
                statement = insert(RateBucket).values(key=key, window=window, count=1)
                statement = statement.on_conflict_do_update(
                    index_elements=[RateBucket.key, RateBucket.window],
                    set_={"count": RateBucket.count + 1},
                ).returning(RateBucket.count)
                count = db.scalar(statement)
                db.execute(delete(RateBucket).where(RateBucket.window < window - 2))
                db.commit()
            if count > limit:
                return await reject(429, "Too many requests. Retry in a minute.")
        cap = cfg.max_audio_bytes + 65536 if path == "/api/v1/scans/voice" else 1024 * 1024
        headers = dict(scope["headers"])
        try:
            declared = int(headers.get(b"content-length", b"0"))
        except ValueError:
            return await reject(400, "Invalid request length")
        if declared > cap:
            return await reject(413, "Request too large")
        chunks, size = [], 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            size += len(message.get("body", b""))
            if size > cap:
                return await reject(413, "Request too large")
            chunks.append(message.get("body", b""))
            if not message.get("more_body", False):
                break
        consumed = False

        async def replay():
            nonlocal consumed
            if not consumed:
                consumed = True
                return {"type": "http.request", "body": b"".join(chunks), "more_body": False}
            return await receive()

        async def safe_send(message):
            if message["type"] == "http.response.start":
                message.setdefault("headers", []).extend(
                    [
                        (b"x-content-type-options", b"nosniff"),
                        (b"cache-control", b"no-store"),
                        (b"referrer-policy", b"no-referrer"),
                    ]
                )
                logger.info(
                    json.dumps(
                        {
                            "event": "request",
                            "method": scope["method"],
                            "status": message["status"],
                            "latency_ms": round((time.monotonic() - started) * 1000),
                        }
                    )
                )
            await send(message)

        await self.app(scope, replay, safe_send)

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.api import auth, reports, scans, users
from app.core.config import settings
from app.core.database import SessionLocal
from app.middleware import Boundaries
from app.services.detection import model

logging.basicConfig(level=logging.INFO, format="%(message)s")
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("httpcore").setLevel(logging.WARNING)


@asynccontextmanager
async def lifespan(app):
    # Configured invalid models fail startup, rather than silently switching engines.
    model()
    yield


app = FastAPI(
    title="AI-Powered Multi-Channel Fraud Detection System", version="0.1.0", lifespan=lifespan
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings().cors_origins,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
app.add_middleware(Boundaries)
for router in [auth.router, users.router, scans.router, reports.router]:
    app.include_router(router, prefix="/api/v1")


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc):
    # Pydantic normally includes offending input, potentially passwords or private scan bodies.
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Input validation failed",
            "fields": [".".join(str(v) for v in e["loc"]) for e in exc.errors()],
        },
    )


@app.exception_handler(Exception)
async def unexpected(request: Request, exc):
    logging.getLogger("scan_shield").error('{"event":"internal_error"}')
    return JSONResponse(status_code=500, content={"detail": "Service error; please retry later"})


@app.get("/health")
def health():
    return {"status": "ok", "version": "0.1.0"}


@app.get("/ready")
def ready():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1 FROM users LIMIT 1"))
        return {"status": "ready"}
    except Exception:
        return JSONResponse(
            status_code=503, content={"status": "database or migrations unavailable"}
        )


@app.get("/api/v1/capabilities")
def capabilities():
    cfg = settings()
    return {
        "engine": "model-and-rules" if model().version else "rule-baseline",
        "model_version": model().version,
        "speech": bool(cfg.speech_model_path),
        "reputation": cfg.reputation_provider != "disabled" and bool(cfg.reputation_api_key),
        "email_delivery": bool(cfg.smtp_host),
        "automatic_monitoring": False,
        "audio_processing": "local backend CPU; audio leaves device, deleted after processing",
    }

import email.policy
from email.parser import BytesParser
from typing import Literal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy import delete, func, select
from starlette.concurrency import run_in_threadpool

from app.core.config import settings
from app.core.database import get_db
from app.models import Alert, Feedback, Scan
from app.schemas import FeedbackInput, ScanInput, ScanResult
from app.security import current_user
from app.services.detection import detect
from app.services.providers import transcribe
from app.services.storage import owned_scan, purge_user, save_scan, scan_json

router = APIRouter(prefix="/scans", tags=["scans"])


@router.post("", status_code=201, response_model=ScanResult, response_model_exclude_none=True)
def submit(body: ScanInput, user=Depends(current_user), db=Depends(get_db)):
    try:
        result = detect(body)
    except ValueError as exc:
        raise HTTPException(422, "Invalid URL or detection configuration") from exc
    return save_scan(db, user, body.channel, result)


@router.post("/voice", status_code=201, response_model=ScanResult, response_model_exclude_none=True)
async def voice(file: UploadFile = File(), user=Depends(current_user), db=Depends(get_db)):
    try:
        if not (file.filename or "").lower().endswith(".wav"):
            raise HTTPException(422, "Only PCM WAV files are supported")
        data = await file.read(settings().max_audio_bytes + 1)
        transcript = await run_in_threadpool(transcribe, data)
        result = await run_in_threadpool(detect, ScanInput(channel="voice", content=transcript))
        # Transcript is returned for immediate review, but excluded from persisted result.
        return {**save_scan(db, user, "voice", result), "transcript": transcript}
    finally:
        await file.close()


@router.post(
    "/email-file", status_code=201, response_model=ScanResult, response_model_exclude_none=True
)
async def email_file(file: UploadFile = File(), user=Depends(current_user), db=Depends(get_db)):
    try:
        raw = await file.read(512 * 1024 + 1)
        if len(raw) > 512 * 1024 or not (file.filename or "").lower().endswith(".eml"):
            raise HTTPException(422, "Import an .eml file of at most 512 KB")
        message = BytesParser(policy=email.policy.default).parsebytes(raw)
        bodies, names = [], []
        for part in message.walk():
            if part.get_filename():
                names.append(part.get_filename()[:200])
            elif part.get_content_type() == "text/plain":
                bodies.append(part.get_content())
        text = "\n".join(bodies)
        if not text.strip():
            raise HTTPException(422, "A plain-text email body is required; HTML is not rendered")
        from email.utils import parseaddr

        body = ScanInput(
            channel="email",
            content=text,
            subject=str(message.get("Subject", "")),
            sender=parseaddr(str(message.get("From", "")))[1] or None,
            reply_to=parseaddr(str(message.get("Reply-To", "")))[1] or None,
            attachment_names=names,
        )
        result = await run_in_threadpool(detect, body)
        return save_scan(db, user, "email", result)
    except (ValueError, LookupError) as exc:
        raise HTTPException(422, "Invalid or unsupported email file") from exc
    finally:
        await file.close()


@router.get("")
def history(
    channel: Literal["sms", "email", "url", "voice", "call"] | None = None,
    risk: Literal["Safe", "Suspicious", "High Risk"] | None = None,
    start: float | None = None,
    end: float | None = None,
    search: str = Query(default="", max_length=80),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    user=Depends(current_user),
    db=Depends(get_db),
):
    purge_user(db, user)
    query = select(Scan).where(Scan.user_id == user.id)
    if channel:
        query = query.where(Scan.channel == channel)
    if risk:
        query = query.where(Scan.risk_level == risk)
    if start is not None:
        query = query.where(Scan.created_at >= start)
    if end is not None:
        query = query.where(Scan.created_at <= end)
    if search:
        query = query.where(Scan.id.contains(search, autoescape=True))
    total = db.scalar(select(func.count()).select_from(query.subquery()))
    items = db.scalars(query.order_by(Scan.created_at.desc()).offset(offset).limit(limit))
    return {
        "items": [scan_json(s) for s in items],
        "total": total,
        "offset": offset,
        "limit": limit,
    }


@router.get("/summary")
def summary(user=Depends(current_user), db=Depends(get_db)):
    purge_user(db, user)
    rows = db.execute(
        select(Scan.risk_level, func.count())
        .where(Scan.user_id == user.id)
        .group_by(Scan.risk_level)
    ).all()
    channels = db.execute(
        select(Scan.channel, func.count()).where(Scan.user_id == user.id).group_by(Scan.channel)
    ).all()
    return {
        "total": sum(row[1] for row in rows),
        "risk_distribution": dict(rows),
        "channels": dict(channels),
    }


@router.delete("")
def clear(user=Depends(current_user), db=Depends(get_db)):
    db.execute(delete(Scan).where(Scan.user_id == user.id))
    db.commit()
    return {"message": "All scan history and linked feedback, reports and alerts deleted"}


@router.get("/{scan_id}", response_model=ScanResult, response_model_exclude_none=True)
def detail(scan_id: str, user=Depends(current_user), db=Depends(get_db)):
    return scan_json(owned_scan(db, user, scan_id))


@router.delete("/{scan_id}")
def remove(scan_id: str, user=Depends(current_user), db=Depends(get_db)):
    scan = owned_scan(db, user, scan_id)
    db.delete(scan)
    db.commit()
    return {"message": "Scan and linked records deleted"}


@router.put("/{scan_id}/feedback")
def feedback(scan_id: str, body: FeedbackInput, user=Depends(current_user), db=Depends(get_db)):
    owned_scan(db, user, scan_id)
    record = db.scalar(
        select(Feedback).where(Feedback.scan_id == scan_id, Feedback.user_id == user.id)
    )
    if record is None:
        record = Feedback(scan_id=scan_id, user_id=user.id)
        db.add(record)
    record.verdict, record.comment = body.verdict, body.comment
    db.commit()
    return {"message": "Feedback saved. Production models are not retrained automatically."}


@router.get("/{scan_id}/alert")
def scan_alert(scan_id: str, user=Depends(current_user), db=Depends(get_db)):
    owned_scan(db, user, scan_id)
    alert = db.scalar(select(Alert).where(Alert.scan_id == scan_id, Alert.user_id == user.id))
    return {"enabled": alert is not None, "read": alert.read if alert else None}

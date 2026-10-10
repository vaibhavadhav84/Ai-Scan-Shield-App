import time

from fastapi import HTTPException
from sqlalchemy import delete, select

from app.models import Alert, Scan


def purge_user(db, user):
    cutoff = time.time() - user.retention_days * 86400
    db.execute(delete(Scan).where(Scan.user_id == user.id, Scan.created_at < cutoff))
    db.commit()


def owned_scan(db, user, scan_id):
    purge_user(db, user)
    scan = db.scalar(select(Scan).where(Scan.id == scan_id, Scan.user_id == user.id))
    if not scan:
        raise HTTPException(404, "Scan not found")
    return scan


def save_scan(db, user, channel, result):
    scan = Scan(
        user_id=user.id,
        channel=channel,
        score=result["score"],
        risk_level=result["risk_level"],
        result=result,
    )
    db.add(scan)
    db.flush()
    if user.alerts_enabled and result["risk_level"] != "Safe":
        db.add(Alert(user_id=user.id, scan_id=scan.id, severity=result["risk_level"]))
    db.commit()
    return scan_json(scan)


def scan_json(scan):
    return {"id": scan.id, "channel": scan.channel, "created_at": scan.created_at, **scan.result}


def user_json(user):
    return {
        "id": user.id,
        "email": user.email,
        "display_name": user.display_name,
        "verified": user.verified,
        "alerts_enabled": user.alerts_enabled,
        "retention_days": user.retention_days,
    }


def report_json(report):
    return {
        "id": report.id,
        "scan_id": report.scan_id,
        "category": report.category,
        "status": report.status,
        "created_at": report.created_at,
    }

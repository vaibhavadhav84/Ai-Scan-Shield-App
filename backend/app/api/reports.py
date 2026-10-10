from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.models import Alert, AuditEvent, Feedback, Report, Scan
from app.schemas import Moderation, ReportInput
from app.security import administrator, current_user
from app.services.detection import model
from app.services.storage import owned_scan, purge_user, report_json

router = APIRouter(tags=["reports and alerts"])


@router.post("/reports", status_code=201)
def report(body: ReportInput, user=Depends(current_user), db=Depends(get_db)):
    owned_scan(db, user, body.scan_id)
    item = Report(
        user_id=user.id, scan_id=body.scan_id, category=body.category, comment=body.comment
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(409, "This scan has already been reported") from exc
    return report_json(item)


@router.get("/reports")
def reports(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    user=Depends(current_user),
    db=Depends(get_db),
):
    purge_user(db, user)
    items = db.scalars(
        select(Report)
        .where(Report.user_id == user.id)
        .order_by(Report.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    return {"items": [report_json(r) for r in items]}


@router.get("/alerts")
def alerts(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    user=Depends(current_user),
    db=Depends(get_db),
):
    purge_user(db, user)
    items = db.scalars(
        select(Alert)
        .where(Alert.user_id == user.id)
        .order_by(Alert.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    return {
        "items": [
            {
                "id": a.id,
                "scan_id": a.scan_id,
                "read": a.read,
                "severity": a.severity,
                "created_at": a.created_at,
                "message": "Review your scan before taking action.",
            }
            for a in items
        ]
    }


@router.patch("/alerts/{alert_id}/read")
def mark_read(alert_id: str, user=Depends(current_user), db=Depends(get_db)):
    purge_user(db, user)
    alert = db.scalar(select(Alert).where(Alert.id == alert_id, Alert.user_id == user.id))
    if not alert:
        raise HTTPException(404, "Alert not found")
    alert.read = True
    db.commit()
    return {"message": "Alert marked read"}


@router.get("/admin/metrics")
def metrics(user=Depends(administrator), db=Depends(get_db)):
    risk = db.execute(select(Scan.risk_level, func.count()).group_by(Scan.risk_level)).all()
    channel = db.execute(select(Scan.channel, func.count()).group_by(Scan.channel)).all()
    feedback = db.execute(select(Feedback.verdict, func.count()).group_by(Feedback.verdict)).all()
    return {
        "scans": sum(n for _, n in risk),
        "risk_distribution": dict(risk),
        "channels": dict(channel),
        "feedback": dict(feedback),
        "model_version": model().version,
    }


@router.get("/admin/reports")
def review(
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    user=Depends(administrator),
    db=Depends(get_db),
):
    # No user identity, free-text comment or raw communication returned.
    return {
        "items": [
            report_json(r)
            for r in db.scalars(
                select(Report).order_by(Report.created_at.desc()).offset(offset).limit(limit)
            )
        ]
    }


@router.patch("/admin/reports/{report_id}")
def moderate(report_id: str, body: Moderation, user=Depends(administrator), db=Depends(get_db)):
    record = db.get(Report, report_id)
    if not record:
        raise HTTPException(404, "Report not found")
    record.status = body.status
    db.add(AuditEvent(actor_id=user.id, action="report_moderated", target_id=record.id))
    db.commit()
    return report_json(record)

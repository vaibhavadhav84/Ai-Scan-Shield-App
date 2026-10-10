from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select

from app.core.database import get_db
from app.models import Alert, Feedback, Report, Scan
from app.schemas import DeleteAccount, ProfileUpdate
from app.security import current_user, password_matches
from app.services.storage import purge_user, report_json, scan_json, user_json

router = APIRouter(prefix="/users", tags=["account"])


@router.get("/me")
def me(user=Depends(current_user)):
    return user_json(user)


@router.patch("/me")
def update(body: ProfileUpdate, user=Depends(current_user), db=Depends(get_db)):
    user.display_name = body.display_name
    user.alerts_enabled = body.alerts_enabled
    user.retention_days = body.retention_days
    db.commit()
    purge_user(db, user)
    return user_json(user)


@router.get("/me/export")
def export(user=Depends(current_user), db=Depends(get_db)):
    purge_user(db, user)
    return {
        "profile": user_json(user),
        "scans": [scan_json(s) for s in db.scalars(select(Scan).where(Scan.user_id == user.id))],
        "reports": [
            {**report_json(r), "comment": r.comment}
            for r in db.scalars(select(Report).where(Report.user_id == user.id))
        ],
        "feedback": [
            {"scan_id": f.scan_id, "verdict": f.verdict, "comment": f.comment}
            for f in db.scalars(select(Feedback).where(Feedback.user_id == user.id))
        ],
        "alerts": [
            {"scan_id": a.scan_id, "read": a.read, "severity": a.severity}
            for a in db.scalars(select(Alert).where(Alert.user_id == user.id))
        ],
    }


@router.delete("/me")
def delete_account(body: DeleteAccount, user=Depends(current_user), db=Depends(get_db)):
    if not password_matches(user.password_hash, body.password):
        raise HTTPException(401, "Password incorrect")
    db.delete(user)
    db.commit()
    return {"message": "Account and associated application records deleted"}

import secrets
import time

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError

from app.core.config import settings
from app.core.database import get_db
from app.models import ActionToken, SessionToken, User
from app.schemas import EmailRequest, Login, Register, Reset, TokenRequest
from app.security import (
    current_session,
    current_user,
    digest,
    hasher,
    issue_session,
    password_matches,
    revoke_all,
    throttle_account,
)
from app.services.mail import send_action

router = APIRouter(prefix="/auth", tags=["authentication"])
# Used to reduce account-existence timing differences for unsuccessful login.
dummy_hash = hasher.hash(secrets.token_urlsafe(32))


def action(db, user, purpose):
    token = secrets.token_urlsafe(32)
    delivery = send_action(user.email, purpose, token)
    db.execute(
        delete(ActionToken).where(ActionToken.user_id == user.id, ActionToken.purpose == purpose)
    )
    db.add(
        ActionToken(
            user_id=user.id,
            purpose=purpose,
            token_hash=digest(token),
            expires_at=time.time() + 1800,
        )
    )
    db.commit()
    return delivery


@router.post("/register", status_code=201)
def register(body: Register, db=Depends(get_db)):
    email = str(body.email).lower()
    user = User(
        email=email, password_hash=hasher.hash(body.password), display_name=body.display_name
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(409, "Account cannot be created with those details") from exc
    try:
        delivery = action(db, user, "verify")
    except HTTPException:
        # Keep registered account recoverable through resend, report delivery accurately.
        delivery = {"delivery": "unavailable; request verification again"}
    return {"message": "Account created. Verify your email before production sign-in.", **delivery}


@router.post("/login")
def login(body: Login, db=Depends(get_db)):
    throttle_account(db, str(body.email))
    user = db.scalar(select(User).where(User.email == str(body.email).lower()))
    valid = password_matches(user.password_hash if user else dummy_hash, body.password)
    if not user or not valid:
        raise HTTPException(401, "Invalid email or password")
    if settings().environment == "production" and not user.verified:
        raise HTTPException(403, "Verify your email before signing in")
    # Limit live sessions; oldest first so retained devices cannot expand storage indefinitely.
    tokens = db.scalars(
        select(SessionToken)
        .where(SessionToken.user_id == user.id)
        .order_by(SessionToken.created_at.desc())
    ).all()
    for token in tokens[9:]:
        db.delete(token)
    return issue_session(db, user)


@router.post("/refresh")
def refresh(body: TokenRequest, db=Depends(get_db)):
    token = db.scalar(
        select(SessionToken)
        .where(
            SessionToken.refresh_hash == digest(body.token),
            SessionToken.refresh_expires > time.time(),
        )
        .with_for_update()
    )
    if not token:
        raise HTTPException(401, "Refresh session expired or revoked")
    user = db.get(User, token.user_id)
    # Delete old pair and create a new one in the same committed transaction.
    removed = db.execute(
        delete(SessionToken).where(
            SessionToken.id == token.id, SessionToken.refresh_hash == digest(body.token)
        )
    )
    if removed.rowcount != 1:
        db.rollback()
        raise HTTPException(401, "Refresh session expired or revoked")
    return issue_session(db, user)


@router.post("/logout")
def logout(token=Depends(current_session), db=Depends(get_db)):
    db.delete(token)
    db.commit()
    return {"message": "Signed out"}


@router.post("/revoke-all")
def revoke(user=Depends(current_user), db=Depends(get_db)):
    revoke_all(db, user.id)
    db.commit()
    return {"message": "All sessions revoked"}


@router.post("/verification/request")
def verification_request(body: EmailRequest, db=Depends(get_db)):
    throttle_account(db, str(body.email), "verification")
    user = db.scalar(select(User).where(User.email == str(body.email).lower()))
    if user and not user.verified:
        action(db, user, "verify")
    return {
        "message": "If eligible, verification instructions will be sent. "
        "In development use the registration token or local admin command."
    }


@router.post("/verification/confirm")
def verification_confirm(body: TokenRequest, db=Depends(get_db)):
    token = db.scalar(
        select(ActionToken)
        .where(
            ActionToken.token_hash == digest(body.token),
            ActionToken.purpose == "verify",
            ActionToken.expires_at > time.time(),
        )
        .with_for_update()
    )
    if not token:
        raise HTTPException(400, "Invalid or expired verification token")
    user = db.get(User, token.user_id)
    user.verified = True
    db.delete(token)
    db.commit()
    return {"message": "Email verified"}


@router.post("/password/request")
def reset_request(body: EmailRequest, db=Depends(get_db)):
    throttle_account(db, str(body.email), "reset")
    user = db.scalar(select(User).where(User.email == str(body.email).lower()))
    # Never expose a reset token to an unauthenticated request, including development mode.
    if user and settings().smtp_host:
        action(db, user, "reset")
    return {
        "message": "If eligible and email delivery is configured, reset instructions will be sent."
    }


@router.post("/password/confirm")
def reset_confirm(body: Reset, db=Depends(get_db)):
    token = db.scalar(
        select(ActionToken)
        .where(
            ActionToken.token_hash == digest(body.token),
            ActionToken.purpose == "reset",
            ActionToken.expires_at > time.time(),
        )
        .with_for_update()
    )
    if not token:
        raise HTTPException(400, "Invalid or expired reset token")
    user = db.get(User, token.user_id)
    user.password_hash = hasher.hash(body.password)
    db.execute(delete(ActionToken).where(ActionToken.user_id == user.id))
    revoke_all(db, user.id)
    db.commit()
    return {"message": "Password reset. Sign in again."}

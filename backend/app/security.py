import hashlib
import secrets
import time

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.models import RateBucket, SessionToken, User


def throttle_account(db, email, group="login"):
    from sqlalchemy.dialects.postgresql import insert as pg_insert
    from sqlalchemy.dialects.sqlite import insert as sqlite_insert

    key = digest(f"account:{group}:{email.lower()}")
    window = int(time.time() // 60)
    insert = sqlite_insert if db.bind.dialect.name == "sqlite" else pg_insert
    statement = insert(RateBucket).values(key=key, window=window, count=1)
    statement = statement.on_conflict_do_update(
        index_elements=[RateBucket.key, RateBucket.window], set_={"count": RateBucket.count + 1}
    ).returning(RateBucket.count)
    count = db.scalar(statement)
    db.commit()
    if count > settings().auth_rate_limit:
        raise HTTPException(429, "Too many account requests. Retry in a minute.")


hasher = PasswordHasher()
bearer = HTTPBearer(auto_error=False)


def digest(token: str):
    return hashlib.sha256(token.encode()).hexdigest()


def password_matches(encoded, password):
    try:
        return hasher.verify(encoded, password)
    except (VerificationError, InvalidHashError):
        return False


def issue_session(db: Session, user: User):
    access, refresh = secrets.token_urlsafe(32), secrets.token_urlsafe(48)
    now = time.time()
    db.add(
        SessionToken(
            user_id=user.id,
            access_hash=digest(access),
            refresh_hash=digest(refresh),
            access_expires=now + settings().access_minutes * 60,
            refresh_expires=now + settings().refresh_days * 86400,
        )
    )
    db.commit()
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": settings().access_minutes * 60,
    }


def current_session(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
):
    if not credentials:
        raise HTTPException(401, "Sign in required")
    token = db.scalar(
        select(SessionToken).where(
            SessionToken.access_hash == digest(credentials.credentials),
            SessionToken.access_expires > time.time(),
        )
    )
    if not token:
        raise HTTPException(401, "Session expired or revoked")
    return token


def current_user(token: SessionToken = Depends(current_session), db=Depends(get_db)):
    user = db.get(User, token.user_id)
    if not user:
        raise HTTPException(401, "Session expired or revoked")
    return user


def administrator(user: User = Depends(current_user)):
    if not user.admin:
        raise HTTPException(403, "Administrator access required")
    return user


def revoke_all(db, user_id):
    db.execute(delete(SessionToken).where(SessionToken.user_id == user_id))

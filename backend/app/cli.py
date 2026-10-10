"""Explicit local administration. Never expose these operations as public setup endpoints."""

import argparse
import time

from sqlalchemy import delete, select

from app.core.database import SessionLocal
from app.models import ActionToken, AuditEvent, SessionToken, User
from app.services.storage import purge_user


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["purge", "promote", "demote"])
    parser.add_argument("--email")
    args = parser.parse_args()
    with SessionLocal() as db:
        if args.command == "purge":
            for user in db.scalars(select(User)).all():
                purge_user(db, user)
            db.execute(delete(SessionToken).where(SessionToken.refresh_expires < time.time()))
            db.execute(delete(ActionToken).where(ActionToken.expires_at < time.time()))
            db.commit()
            print("Expired history and credentials purged")
        else:
            if not args.email:
                parser.error("--email required")
            user = db.scalar(select(User).where(User.email == args.email.lower()))
            if not user:
                parser.error("Account not found")
            user.admin = args.command == "promote"
            db.add(AuditEvent(actor_id=None, action=args.command, target_id=user.id))
            db.commit()
            print("Administrator privilege updated and audited")


if __name__ == "__main__":
    main()

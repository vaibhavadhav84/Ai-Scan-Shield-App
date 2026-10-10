import smtplib
import ssl
from email.message import EmailMessage

from fastapi import HTTPException

from app.core.config import settings


def send_action(email, purpose, token):
    """No tokens are logged. Dev returns a token only to the requester, never in production."""
    cfg = settings()
    if not cfg.smtp_host:
        if cfg.environment == "production":
            raise HTTPException(503, "Email service unavailable")
        return {"development_token": token, "delivery": "development-only; no email sent"}
    message = EmailMessage()
    message["From"] = cfg.mail_from
    message["To"] = email
    message["Subject"] = f"Scan Shield: {purpose}"
    message.set_content(
        f"Your {purpose} token is:\n{token}\n\nExpires in 30 minutes. "
        "Enter it in Scan Shield. If you did not request it, ignore this email."
    )
    try:
        with smtplib.SMTP(cfg.smtp_host, cfg.smtp_port, timeout=10) as client:
            client.starttls(context=ssl.create_default_context())
            if cfg.smtp_user:
                client.login(cfg.smtp_user, cfg.smtp_password)
            client.send_message(message)
    except (OSError, smtplib.SMTPException) as exc:
        raise HTTPException(503, "Email service unavailable; try again later") from exc
    return {"delivery": "email"}

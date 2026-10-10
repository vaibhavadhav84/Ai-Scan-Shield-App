# Credentials and providers
No provider credential is needed for local rules-only scans, accounts and SQLite.
Keep values in ignored backend/.env (Python) or root .env (Compose), or production secrets manager.
Never put a backend key into Flutter or paste production secrets into chat.

| Service | Purpose and setup | Variables | Need, cost, test and rotation |
|---|---|---|---|
| PostgreSQL operator | Create dedicated database/user with access only to application DB; no cluster admin | DATABASE_URL, Compose POSTGRES_PASSWORD | Required production; hosting costs chosen by owner; migrate + /ready; rotate password and reconnect |
| SMTP STARTTLS operator-selected service | Obtain sending-only SMTP credentials and approved sender; port 587; no mailbox-read permissions | SMTP_HOST/PORT/USER/PASSWORD, MAIL_FROM | Required production verification/reset; price depends on service; verify actual email receipt and one-time token; revoke sending credential and replace |
| Local faster-whisper | Install backend[voice], provision approved local model directory from its documented model source, review model license | SPEECH_MODEL_PATH | Optional voice upload; no API key, local CPU/disk cost; submit a consented PCM WAV and inspect transcript; replace/revoke model directory |
| Google Safe Browsing v4 | Enable API in a Google Cloud project, create server key restricted to that API and server source IP where possible | REPUTATION_PROVIDER=google-safe-browsing, REPUTATION_API_KEY | Optional noncommercial use; quota in Google console; known provider test URL via API with consent; rotate/revoke key in console |
| Android release signing | Owner-generated private keystore stored outside repo; signing-only access | Android signing config described in DEPLOYMENT | Required store distribution; store enrollment cost depends on platform; verify signed AAB; protect/rotate using store signing process |

Google Safe Browsing usage restrictions: https://developers.google.com/safe-browsing/v4/usage-limits
It is for noncommercial use; commercial deployment requires a separate approved Web Risk adapter.
No live provider credentials, push service, cloud account or managed auth were selected/tested.
SMTP has no selected vendor; choose one and confirm sending limits, regional processing and cost
before enabling. Development registration returns a clearly marked verification token. Password
reset is unavailable without email delivery and never leaks a reset token to the requester.

Google Safe Browsing also requires REPUTATION_NONCOMMERCIAL_USE=true, and each URL request must explicitly set allow_external_reputation=true after user consent. Internal destinations are never sent.

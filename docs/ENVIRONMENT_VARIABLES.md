# Environment variables
Pydantic Settings loads backend working-directory .env; environment values override the file.
Unknown keys are ignored so Compose-only fields can share the example. Startup validates mode,
positive session/rate limits, risk boundary ordering and required production DB/SMTP settings.

| Variable | Default | Meaning |
|---|---|---|
| ENVIRONMENT | development | development/test/production; production HTTPS + verified login |
| DATABASE_URL | sqlite:///./scanshield.db | SQLAlchemy database URL; PostgreSQL required production |
| CORS_ORIGINS | [] | JSON origin allowlist; native clients need no browser wildcard |
| ACCESS_MINUTES / REFRESH_DAYS | 30 / 14 | Access / refresh expiry |
| RATE_LIMIT / AUTH_RATE_LIMIT | 120 / 15 | Requests per client/group/minute |
| SAFE_THRESHOLD / HIGH_THRESHOLD | 30 / 70 | Safe upper bound, suspicious upper bound |
| MODEL_PATH | empty | Trusted local versioned joblib; empty uses rules |
| SPEECH_MODEL_PATH | empty | Local faster-whisper directory; empty makes voice upload 503 |
| MAX_AUDIO_BYTES / MAX_AUDIO_SECONDS | 10485760 / 180 | PCM WAV upload limits |
| REPUTATION_PROVIDER / REPUTATION_API_KEY | disabled / empty | Disabled or google-safe-browsing |
| SMTP_HOST / SMTP_PORT | empty / 587 | STARTTLS sending host |
| SMTP_USER / SMTP_PASSWORD / MAIL_FROM | empty | Sending-only auth and approved sender |
| POSTGRES_PASSWORD | example placeholder | Compose DB bootstrap, replace locally |
| API_BASE_URL | http://10.0.2.2:8000/api/v1 | Flutter compile-time --dart-define, public API URL only |

Absolute paths are preferred for server model directories. Mobile contains no private keys.
No universal secret is needed because opaque tokens are random and stored hashed.

Google Safe Browsing also requires REPUTATION_NONCOMMERCIAL_USE=true, and each URL request must explicitly set allow_external_reputation=true after user consent. Internal destinations are never sent.

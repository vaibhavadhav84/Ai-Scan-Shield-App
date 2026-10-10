# Architecture
Flutter client uses Riverpod dependency injection/preferences, GoRouter navigation, Dio with
timeouts and serialized token refresh, OS secure storage, and an Android/iOS SQLite cache.
UI modules consume API repositories; shared components render risk, evidence and states.

FastAPI serves /api/v1. Pydantic validates bounded inputs. SQLAlchemy transactions persist
user-owned records; Alembic revisions define the database. SQLite is local-only; production
configuration requires PostgreSQL and SMTP. Opaque access/refresh tokens are hashed, expire,
rotate and revoke. Middleware bounds streamed input before parsing and applies database
rate limits. No endpoint fetches a submitted URL or executes email attachments.

Detection separates rules, score combination, explanation templates and versioned optional
ML. Inference never trains. Reputation targets only the fixed Google Safe Browsing endpoint.
Local faster-whisper is optional; uploaded PCM WAV files are validated before decoding.
Audio exits the device but processing runs on the configured backend CPU.

Monorepo: .codex (engineering), backend (API/migrations/tests), mobile (Android/iOS/client/tests),
ml (training/data policy/artifacts), assets (branding), infrastructure (container), scripts
(admin support/reproducibility), docs, and .github/workflows. See REPOSITORY_STRUCTURE.md.
One service plus database is intentional. No Redis, background queue or LLM is required.

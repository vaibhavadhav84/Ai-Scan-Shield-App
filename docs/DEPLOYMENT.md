# Deployment procedures
This is a development candidate; see RELEASE_CHECKLIST before public deployment.
Docker is not installed here, so container/PostgreSQL startup has not been locally verified.

Local container setup: install Docker, copy .env.example to root .env, set a random
POSTGRES_PASSWORD, keep ENVIRONMENT=development, then `docker compose up --build -d`.
API binds host loopback 8000; PostgreSQL is private. Compose runs Alembic before Uvicorn and
hourly retention cleanup. Dockerfile runs as non-root with read-only root and bounded /tmp.
requirements.lock pins exact resolved Python versions; pubspec.lock pins Flutter dependencies.

Production: set ENVIRONMENT=production, PostgreSQL connection, valid SMTP and HTTPS API URL.
Place API behind a TLS reverse proxy; forward scheme only from a trusted proxy address.
Pass Uvicorn `--proxy-headers --forwarded-allow-ips=<actual private proxy IP>`.
Do not expose the API's HTTP port publicly or trust all internet-supplied forwarding headers.
Update readiness probing to use the TLS edge or a trusted HTTPS forwarded scheme in production;
the included HTTP Compose healthcheck is for local development.
Separate migration execution from concurrent replicas. Back up before migration, inspect
alembic upgrade/downgrade on a copy, and retain previous image/model for rollback.
Apply proxy request/concurrency/time limits, CPU/memory limits, redacted telemetry and alerting.

Flutter debug: `flutter build apk --debug`. Release: configure owner keystore, signing credentials
outside repo, and HTTPS API_BASE_URL; run `flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api-host/api/v1`.
Do not ship debug-signed builds or cleartext URLs. iOS requires macOS/Xcode signing and device
verification. API provider keys stay server-side. No hosting account or live deployment is created.

Android release signing is enforced: set ANDROID_KEYSTORE_PATH (absolute local path), ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD in the build environment. Missing values fail release builds. Debug APKs are development-only.

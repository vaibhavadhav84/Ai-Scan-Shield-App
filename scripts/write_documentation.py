"""Keep setup and requirements documentation linked to real implementation boundaries."""

from pathlib import Path

root = Path(__file__).resolve().parents[1]


def write(name, text):
    destination = root / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text.strip() + "\n", encoding="utf-8")


pages = {
    "PRODUCT_REQUIREMENTS": """# Product requirements
Primary functional reference: supplied 23-page presentation, including image-based tables on
pages 13-20. Only technical requirements are recorded. The pasted master prompt expands its
scope with privacy, authentication lifecycle, deployment and quality requirements.

| Source ID | Requirement | Implementation boundary |
|---|---|---|
| FR1 | Registration/login | Argon2, revocable sessions, verification/reset tokens |
| FR2 | SMS analysis | Manually submitted text; contextual English rules |
| FR3 | Email analysis | Sender/reply-to, subject/body, .eml and attachment filenames |
| FR4 | URL analysis | Parsing and lexical indicators; optional fixed reputation API |
| FR5 | Voice analysis | PCM WAV upload, local speech adapter, transcript rules |
| FR6 | Classification | Safe / Suspicious / High Risk |
| FR7 | Risk score | Integer 0-100, configurable boundaries 30/70 |
| FR8 | Alerts | Preference-aware in-app records and read state |
| FR9 | Explanations | Structured evidence, score rationale, next actions, limitations |
| FR10 | History | Ownership, pagination, filters, ID search, deletion/export |
| FR11 | Feedback | Four verdicts; optional API comments, controlled future training |
| FR12 | Scam reporting | Duplicate prevention, internal moderation and audit |

NFRs: performance (bounded input, benchmark); security (ownership and abuse tests); privacy
(metadata-only history and retention); accuracy (held-out spam baseline, fraud validation pending);
scalability (PostgreSQL extension, deployment load checks pending); availability (health/readiness,
backups); usability (Material 3, states and accessibility tests); maintainability (modules and CI);
reliability (deterministic regression corpus); explainability (evidence-linked scores).
No guarantee of protection. Source future scope remains deferred: regional language modeling,
deepfakes, live calls, browser/banking/enterprise integrations, crowd intelligence, federated
learning and government reporting. Calls use manually supplied descriptions only.
""",
    "ARCHITECTURE": """# Architecture
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
""",
    "ARCHITECTURE_DIAGRAM": """# Component diagram
```mermaid
flowchart LR
  U[User-selected content] --> F[Flutter client]
  F -->|HTTPS /api/v1| V[Validation and body limits]
  V --> A[Authentication and ownership]
  A --> D[Detection orchestrator]
  D --> R[Contextual and lexical rules]
  D --> M[Optional trusted model]
  D --> P[Optional fixed reputation provider]
  D --> W[Optional local speech model]
  R --> S[Score and explanations]
  M --> S
  P --> S
  W --> R
  S --> H[(User-owned result metadata)]
  H --> N[In-app alerts/history/feedback/reports]
  N --> F
  T[Offline training and held-out evaluation] --> M
```
""",
    "DATA_FLOW": """# Data flow
Input -> bounded validation -> Unicode-preserving normalization -> contextual/URL/metadata
feature extraction -> rules plus optional model/reputation -> 0-100 score -> templated
explanation -> persisted generic evidence -> preference-aware in-app alert.

Raw content is kept in process memory during a request and never written to scan history.
The immediate voice response includes its transcript for review; the persisted result excludes
it. WAV temporary files are removed on both success and failure. Original audio selected on
a user's device is not owned by the app; app-created recordings are temporary.
Feedback and report comments are separately stored, bounded, and must not contain secrets.
Reputation, when enabled, sends a URL to the configured provider. No target URL is fetched.
History caches contain result metadata only, expire for display after 24 hours, and clear on
sign-in/out, deletion or retention change. New scans require connectivity.
""",
    "THREAT_MODEL": """# Threat model
Assets: passwords, sessions, account email, private submitted content, scores, report comments,
provider keys and trusted model artifacts. Trust boundaries: device/API, API/database,
API/SMTP/reputation, uploaded audio decoder and model provisioning.

| Threat | Control | Residual risk / release action |
|---|---|---|
| Account compromise | Argon2; token hashes/rotation/expiry/revocation; throttling | Add MFA and distributed account abuse review |
| Cross-user access | Every record query scopes owner; 404 for unowned IDs | Exercise PostgreSQL concurrency before release |
| Malicious URL / SSRF | Parse only; fixed provider host; no DNS or redirects | Lexical rules cannot establish website safety |
| Malicious upload | Pre-parser size cap; PCM WAV parameters; plain-text .eml only | Isolate speech decoder in restricted worker before broad public service |
| Injection/model manipulation | Deterministic templates; no LLM tools; bound input | Evasion and adversarial phrasing remain possible |
| Artifact execution | Administrator-only path, hash and library version | joblib remains executable; trusted provisioning required |
| Privacy leakage | No raw history; generic evidence; redacted errors/logs; deletion | Backups, shared-device caches and owner policies require review |
| False positives/negatives | Context pairs, limitations, feedback; explicit unvalidated baseline | Representative fraud evaluation pending |
| Denial of service | Request/rate/audio bounds; provider timeouts | Gateway concurrency and CPU budgets required for speech |
| Admin misuse | Protected aggregates/redacted reports; audit moderation | Operational review of least privilege required |

No automatic SMS/call access, mailbox OAuth, deepfake claims or banking authority.
Use HTTPS, private database network, restricted containers, secret manager and protected backups.
""",
    "SECURITY": """# Security controls
Passwords use Argon2id via argon2-cffi. Random opaque session tokens are SHA-256 hashed in
database, expire after 30 minutes / 14 days by default and rotate on refresh. Logout and
revoke-all invalidate server records. Reset invalidates all sessions and action tokens.
Production sign-in requires email verification. Development unverified login is explicitly
permitted for local testing; never deploy ENVIRONMENT=development publicly.

User routes scope ownership. Admin routes require a server-side admin flag set only with
local CLI. Reports expose no raw content to admins; moderation writes audit events.
Validation errors never echo password/message input. Structured request logs omit URLs,
bodies and headers. Run Uvicorn with --no-access-log; configure proxy logs similarly.
No URL fetching means submitted hosts cannot reach private or metadata networks.
Body limits precede multipart parsing. No executable attachment processing is implemented.
Production requires HTTPS at a trusted reverse proxy. Never trust arbitrary forwarded headers.
Audit dependencies before release and preserve the actual audit report. Reporting process:
use a private owner-controlled channel; no invented public security email is configured.
""",
    "PRIVACY": """# Privacy specification - deployment owner review required
Collected account data: email, optional display name, password hash, verification state,
settings and hashed session/action tokens. Submitted communications are processed transiently.
History stores channel, time, score, generic evidence, engine version and limitations.
Report/feedback comments are retained with the scan; never ask for OTPs or financial identifiers.
No advertising identifiers, tracking SDKs, contacts, inbox scraping or covert call recording.

Default history retention is 30 days, configurable 1-365 days. History reads purge expired data.
Run `python -m app.cli purge` hourly for inactive accounts; Compose includes that worker.
Deleting scans cascades associated alerts, feedback and reports. Account deletion requires
the password and removes user-owned rows and sessions. Database backups cannot be retroactively
edited by this API; define encrypted backup expiry and deletion reconciliation at deployment.
API exports include profile, scans, feedback, reports and alerts, excluding password/token hashes.
Metadata cache is local SQLite for Android/iOS; sensitive tokens use OS secure storage.
Uploaded audio leaves device for backend-local transcription, then temporary files are deleted.
External reputation receives a URL only when configured; owner must disclose provider processing.
Never train on private submissions automatically. Draft privacy text in Help requires owner
approval, deployment identity, region, contact channel and retention/legal review before release.
""",
    "API_REFERENCE": """# API reference
FastAPI OpenAPI: `/openapi.json`; interactive docs: `/docs`. Routes are `/api/v1`.
JSON errors use `detail`; 401 session invalid, 403 admin/verification, 404 unowned/not found,
409 duplicate account/report, 413 body too large, 422 invalid input, 429 throttled, 503 provider.
Use `Authorization: Bearer <access_token>` for authenticated endpoints.

| Group | Routes |
|---|---|
| Auth | POST /auth/register, /login, /refresh, /logout, /revoke-all |
| Email actions | POST /auth/verification/request, /confirm; /auth/password/request, /confirm |
| Account | GET/PATCH/DELETE /users/me; GET /users/me/export |
| Scans | POST/GET/DELETE /scans; GET /scans/summary; GET/DELETE /scans/{id} |
| Imports | POST /scans/voice (multipart PCM WAV); /scans/email-file (.eml) |
| Feedback | PUT /scans/{id}/feedback |
| Reports | POST/GET /reports |
| Alerts | GET /alerts; PATCH /alerts/{id}/read |
| Admin | GET /admin/metrics, /admin/reports; PATCH /admin/reports/{id} |
| Availability | GET /capabilities; /health and /ready outside version prefix |

Example scan JSON: `{"channel":"sms","content":"Send your OTP immediately."}`.
Email optionally adds sender, reply_to, subject and attachment_names. Call accepts contextual
phone_number without phone reputation. A scan result contains id/channel/time, score/risk,
summary, indicators (code/title/points/evidence), recommendations, versions and limitations.
Voice immediately adds transcript, which is absent from persisted history.
History query: channel, risk, start/end Unix seconds, search (ID only), offset, limit 1-100.
Feedback verdict: correct, false_positive, missed_scam, uncertain. Reports category:
credentials, payment, impersonation, investment, other. Moderation: reviewed/dismissed/escalated.
Registration password minimum 12; login max 128. Reset accepts token plus new password.
Development registration may return development_token; production sends only via SMTP.
Reset never exposes tokens to unauthenticated callers. No automatic URL opening endpoint exists.
""",
    "DATABASE_SCHEMA": """# Data model
users: identity, Argon2 hash, verified/admin flags, alert preference, retention and created time.
sessions: owner, access/refresh hashes and expiry; unique hashes and owner index.
action_tokens: hashed one-time verify/reset tokens, owner, purpose and expiry.
scans: owner, channel, score, risk, structured result JSON and time; ownership/channel/risk/time indexes.
feedback: owner + scan, unique pair, verdict and optional bounded comment.
reports: owner + scan, unique pair, category/comment, moderation status and timestamp.
alerts: owner + scan, one per scan, severity/read flag and timestamp.
rate_buckets: hashed client/group key + minute window, count; expired buckets removed.
audit_events: admin actor identifier, action, target identifier and time; no raw content.

Foreign keys cascade user/scan deletion. API always checks ownership before children are written.
Alembic 0001 freezes initial schema; do not replace migration history with current ORM metadata.
Run migrations before service startup. SQLite foreign keys are enabled on application connections.
Production PostgreSQL transactions/concurrency must be verified in the deployment environment.
""",
    "ML_PIPELINE": """# Model workflow
Rules work with empty MODEL_PATH and disclose that no trained model is loaded.
Training is a separate CLI with CSV text,label and provenance JSON source/license/label_definition.
Pipeline: normalize whitespace -> remove duplicate/variable-number/URL templates -> discard
conflicting template labels -> deterministic stratified 70/15/15 train/validation/test split ->
TF-IDF word unigrams/bigrams -> class-balanced logistic regression -> held-out evaluation.
No test data fits vocabulary or weights. Hyperparameters are fixed; no test-set tuning.
Versioned joblib includes its preprocessing pipeline. Manifest includes schema, library version,
SHA-256 and dataset hash; inference fails configured corrupt/incompatible artifacts.

From project root:
```
python scripts/prepare_uci_dataset.py
python ml/training/train.py --dataset ml/data/uci_sms.csv --provenance ml/data/uci_provenance.json --output ml/artifacts/baseline.joblib
```
Downloaded UCI corpus is licensed CC BY 4.0, labels ham/spam, and is for offline SMS evaluation.
Spam is not verified fraud. Model remains disabled by default; do not market its metrics as
multi-channel scam accuracy. A production model needs representative fraud labels, modern
distribution, regional language evaluation, adversarial tests, calibration and drift review.
Never consume joblib artifacts from users. New model deployment requires trusted provisioning,
regression checks and rollback. User feedback is not automatic training input.
""",
    "DEVELOPMENT_SETUP": r"""# Local setup (PowerShell)
Required: Python 3.12+, Flutter 3.41.4/Dart 3.11.1, Android SDK/JDK for Android. Docker optional.
Python executable `python` may be a Windows Store alias; use an installed interpreter.

From the project root:
```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.lock
.\.venv\Scripts\python.exe -m pip install -e backend
Copy-Item .env.example backend/.env
Set-Location backend
..\.venv\Scripts\python.exe -m alembic upgrade head
..\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --no-access-log
```
In a second terminal, from root:
```powershell
Set-Location mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter build apk --debug
```
10.0.2.2 is the Android emulator host alias. A real device needs a reachable development host
on its network. Use debug cleartext only on trusted local networks; release requires HTTPS.
No device is currently attached. Run `flutter doctor` and resolve Android licenses interactively
with `flutter doctor --android-licenses`. Never silently accept license agreements.
iOS: macOS, Xcode, CocoaPods, signing and secure-storage keychain provisioning are required.
SQLAlchemy/SciPy are pinned to compatible versions after Windows blocked newer extension DLLs.
Default rules-only development needs no API keys and uses a local SQLite database.
""",
    "CREDENTIAL_SETUP": """# Credentials and providers
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
""",
    "ENVIRONMENT_VARIABLES": """# Environment variables
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
""",
    "DEPLOYMENT": """# Deployment procedures
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
""",
    "BACKUP_AND_RECOVERY": """# Backup and recovery
Production PostgreSQL: use restricted backup role and `pg_dump --format=custom` to encrypted
storage with access logs and an owner-defined expiry. Never place dumps in the repository.
Local SQLite: stop writes and use SQLite's backup API; copying a live WAL database is insufficient.
Store secrets separately from dumps and encrypt transport/storage. Test restoration into an
isolated empty database with `pg_restore`, then run migrations, /ready and user-isolation smoke tests.
Treat dumps as sensitive: report comments and account emails remain present until backup expiry.
Record deletion requests separately so restoration does not resurrect deleted accounts silently.
Target recovery time/point objectives are owner-defined and must be tested before release.
No backup service has been provisioned or restoration exercise run against production.
""",
    "TROUBLESHOOTING": """# Troubleshooting
- Store-alias Python: select an installed Python 3.12 interpreter instead of WindowsApps alias.
- Database error: run Alembic from backend, confirm DATABASE_URL and /ready.
- Android cannot reach API: emulator uses 10.0.2.2, physical device uses reachable local host;
  start backend on 0.0.0.0 in trusted local development. Release must use HTTPS.
- Voice 503: configure local SPEECH_MODEL_PATH and install backend[voice]; no model is bundled.
- EML 422: use .eml <=512 KB with plain-text body; HTML is not rendered or fetched.
- URL 422: complete HTTP(S) URL, valid host/port, no whitespace/backslash/encoded host.
- Login 403 in production: verify email with SMTP-delivered token; request resend if expired.
- 429: wait for next minute, investigate abuse; don't remove throttling to hide the issue.
- Windows Application Control blocks a DLL/test engine: use approved compatible packages or
  a supported Linux CI environment. Do not disable Windows security policy.
- Android licenses/build: run flutter doctor, review licenses interactively and install required SDK.
- Native widget runner blocked: browser runner `flutter test --platform chrome` may be available;
  native platform/device behavior still requires separate verification.
- Invalid model: verify manifest schema/library/hash and trusted provenance; empty MODEL_PATH
  intentionally selects rules. Do not silently substitute a broken configured model.
""",
    "ACCEPTANCE_CRITERIA": """# Acceptance criteria
Register/login, verify once, refresh rotation, revoke, reset and deletion must preserve identity
boundaries. Passwords/tokens must be hashes; validation must not echo secrets.
Suspicious SMS must yield a real result with 0-100 score, appropriate level, evidence and limits;
ordinary OTP notices/protective instructions must not be flagged by a keyword alone.
Saved results must be retrievable only by owner; feedback/report submission must persist and
reject duplicate reports; deleting a scan must cascade related records.
URL schemes/hosts must be validated without target requests; provider failures must disclose
lexical-only limitations. EML must never run scripts/attachments; malformed WAV must fail before
decoding; missing speech config must be explicit; transcripts must not persist.
Alert preference must suppress new records. History must paginate/filter and have empty/error
states. All sensitive actions must handle API failures without fabricated success.
Mobile must pass analyzer/widget/navigation/repository tests, build and complete device journeys
before release. Backend must start after migrations and pass ownership/upload/retention/ML tests.
External providers require actual credentialed verification. Model accuracy claims require
representative held-out fraud data; spam-baseline results do not satisfy that release gate.
""",
    "KNOWN_LIMITATIONS": """# Known limitations
English contextual rules can be evaded, miss scams and flag legitimate requests. Unicode is
preserved but regional-language modeling is not validated. Initial risk thresholds are product
heuristics, not calibrated fraud probabilities. No assurance of safety is provided.
Offline SMS spam model evaluation does not validate multi-channel fraud detection; model is
disabled by default. No automatic inbox/call access, mailbox OAuth, real-time analysis, sender
authentication, SPF/DKIM/DMARC validation, phone intelligence or deepfake detection.
URLs are never visited; no live certificate/domain age/redirect/DNS analysis. Optional reputation
requires approved noncommercial configuration; no live API key test has run.
Only PCM WAV, max 10 MB/180s; no speech model bundled; no live transcription/device microphone
verification. Local and push notifications beyond in-app alert records are not implemented.
Anonymous scanning is not enabled. Feedback comments are supported by API; UI offers verdicts.
Offline history is metadata only, has a 24-hour display limit, and cannot perform new scans.
No production hosting, backup, legal review, native platform integration or store signing is done.
See TESTING.md and FEATURE_MATRIX.md for actual command outcomes and outstanding build gates.
""",
    "ROADMAP": """# Prioritized roadmap
1. Resolve local mobile execution/build blockers; verify device recording, secure storage,
   share/export, accessibility, onboarding and complete API journeys on a real Android device.
2. Exercise PostgreSQL migration/concurrency, TLS proxy, SMTP delivery/reset and backup restore;
   provision hosting, rate/concurrency monitoring and reviewed privacy/terms/support.
3. Obtain representative licensed fraud datasets, validate false positives/negatives and
   language/channel coverage; calibrate model before enabling it in deployment.
4. Isolate speech inference, provision approved local model and test consented audio cases.
5. Add device local notifications with permission/duplicate controls; push only with consent
   and a selected service. Add Android share import and richer feedback/offline lifecycle.
6. Add approved commercial reputation adapter if needed, monitored quota and provider evidence.
7. Regional NLP (language datasets), deepfakes (validated models), live calls (supported legal
   device APIs), browser extensions (separate permissions), banking (authorized partners),
   enterprise (tenant authorization), crowd intelligence (moderation), federated learning
   (privacy design) and cybercrime integration (official authorized endpoints).
Extension points: detectors/rules + detection orchestrator, services/providers, ml/inference,
Flutter feature routes and admin API; future features are not decorative completed modules.
""",
    "DECISIONS": """# Architectural decisions
2026-10-10: Flutter/FastAPI monorepo matches source mobile/API requirements. Riverpod, GoRouter,
Dio and secure storage resolved to versions compatible with installed Flutter 3.41.4.
SQLAlchemy 2.0.48, NumPy 2.2.6, SciPy 1.15.3 and sklearn 1.6.1 are pinned after Windows
Application Control blocked newer extension binaries. Security policy remains enabled.
SQLite is developer convenience; PostgreSQL is a production gate. No Redis/queue is required
for bounded synchronous text scans. Local speech is optional, with further isolation needed.
Opaque revocable tokens simplify session invalidation and need no shared signing secret.
Metadata-only history deliberately omits exact phrase evidence and original content to reduce
retention risk; explanations describe observable patterns without storing the submitted phrase.
Lexical-only URL analysis avoids SSRF; a fixed reputation API provides opt-in outside evidence.
Scoring deduplicates rule codes and takes max(rule score, optional model contribution) to avoid
adding correlated signals. Boundaries 30/70 match source and are configurable.
Original vector logo avoids copied branding. .codex role files are documented contracts;
AGENTS.md is runtime instruction entry point. No invented agent configuration or launch claims.
""",
    "RELEASE_CHECKLIST": """# Release checklist
- [ ] Flutter analyzer/tests and actual Android build verified on final code
- [ ] Real device end-to-end journeys, recording, secure storage, export and accessibility
- [ ] PostgreSQL upgrade/downgrade/concurrency and account isolation
- [ ] HTTPS proxy configuration, trusted forwarding and redacted gateway logs
- [ ] SMTP verification/reset receipt and credential rotation
- [ ] Optional speech/reputation configured, consented, quota/failure verified
- [ ] Dependency audit reviewed and no unresolved critical findings
- [ ] Representative fraud dataset evaluation and calibration before accuracy claims
- [ ] Hourly retention, encrypted backup restoration and deletion reconciliation
- [ ] Owner-approved privacy, terms, contact channel and recording obligations
- [ ] Android release signing / iOS provisioning and store requirements
- [ ] Load, latency, availability monitoring and incident procedures
- [ ] Feature matrix and test report match evidence; no fake outcomes
""",
    "USER_GUIDE": """# Using Scan Shield
Start with onboarding to learn supported channels and privacy limits. Register an email and
12-character password, verify through the delivered token, then sign in. Local development
may fill a clearly marked verification token without sending email.
Home shows only your actual stored scans. Select SMS/text, Email, URL, Voice or Call details.
Paste/type content and select Analyze. For email, add available sender/reply-to/subject or
import plain-text .eml. Never open suspicious attachments. Enter full HTTP(S) URLs; the app
does not visit them. For voice, record only with consent, review playback, then upload PCM WAV,
or paste a transcript if speech recognition is unavailable. Call details are manual descriptions.

Review score, category, evidence, next steps and limitations. Safe means no substantial
indicator was found by available checks, not proof. Give a feedback verdict or report from the
result. Reporting is internal review only. History filters channel/risk/date/scan ID and paginates.
Export a result through the share sheet, or delete it and linked records. Alerts link to results
and support mark-read. Reports show actual moderation status.
Profile edits name/theme, in-app alert preference and retention; export all data, revoke sessions
or delete the account with password confirmation. Help explains privacy, permissions and draft terms.
If offline, retry when connected; cached history is labeled and scans remain unavailable.
No support address is configured. Contact the operator of your installation for account/provider issues.
""",
}
for name, content in pages.items():
    write(f"docs/{name}.md", content)

features = [
    (
        "Onboarding",
        "onboarding",
        "/auth",
        "Local completion preference",
        "None",
        "Implemented",
        "widget navigation test",
    ),
    (
        "Accounts",
        "authentication",
        "/auth/*, /users/me",
        "users, sessions, action_tokens",
        "None",
        "Tested",
        "authentication/reset/revocation tests; SMTP/device pending",
    ),
    (
        "Home",
        "dashboard",
        "/scans/summary, /scans, /capabilities",
        "Read owned scans",
        "None",
        "Implemented",
        "summary API; widget/device pending",
    ),
    (
        "SMS/text",
        "scan",
        "/scans",
        "scans, alerts",
        "None",
        "Tested",
        "contextual rules + end-to-end API; device pending",
    ),
    (
        "Email",
        "scan",
        "/scans, /scans/email-file",
        "scans, alerts",
        "System file picker",
        "Tested",
        "metadata/import tests; device pending",
    ),
    (
        "URL",
        "scan",
        "/scans",
        "scans, alerts",
        "None",
        "Tested",
        "parsing/private destination/provider failure tests; live key pending",
    ),
    (
        "Voice",
        "scan",
        "/scans/voice or /scans",
        "scans; temporary WAV deleted",
        "Microphone only on recording",
        "Blocked",
        "invalid/missing-provider/mock-transcript tests; local model not provided",
    ),
    (
        "Call details",
        "scan",
        "/scans",
        "scans, alerts; phone not retained",
        "None",
        "Implemented",
        "text engine reused; caller not authenticated",
    ),
    (
        "Results",
        "results",
        "/scans/{id}",
        "Read scan metadata",
        "None",
        "Tested",
        "score/risk/evidence API; UI/device pending",
    ),
    (
        "History",
        "history",
        "/scans, /scans/{id}",
        "scans; metadata cache",
        "None",
        "Tested",
        "ownership/filter/deletion/retention API; cache/device pending",
    ),
    (
        "Alerts",
        "reports",
        "/alerts",
        "alerts",
        "None",
        "Tested",
        "preference/read-state API; no OS notifications",
    ),
    (
        "Feedback",
        "results",
        "/scans/{id}/feedback",
        "feedback",
        "None",
        "Tested",
        "verdict persistence + ownership; optional comments API only",
    ),
    (
        "Reports/admin",
        "reports",
        "/reports, /admin/*",
        "reports, audit_events",
        "Admin server role for review",
        "Tested",
        "duplicate/ownership/admin API; operational review pending",
    ),
    (
        "Profile/privacy",
        "account",
        "/users/me, /users/me/export",
        "users and cascading children",
        "Share sheet for export",
        "Tested",
        "export/account deletion/retention API; device export pending",
    ),
    (
        "Model training",
        "ml/training",
        "No public training endpoint",
        "Trusted versioned artifact, no private submissions",
        "Administrator provisioning",
        "Tested",
        "held-out SMS spam baseline, functional model loading/hash test",
    ),
]
matrix = [
    "# Feature status and evidence",
    "",
    "Statuses apply to the indicated scope; Tested API does not mean mobile/device/provider validation.",
    "",
    "| Feature | Status | Platform / dependency | Evidence and limitation |",
    "|---|---|---|---|",
]
for name, screen, api, data, permission, status, checks in features:
    matrix.append(f"| {name} | {status} | Flutter/API; {permission} | {checks} |")
matrix += [
    "| Local/push notifications | Deferred | Selected service + runtime consent | In-app alerts only |",
    "| Anonymous mode | Deferred | Abuse/privacy design | Sign-in required |",
    "| Store release/iOS builds | Blocked | Signing, device/macOS | No store release |",
    "| Production hosting/backups | Not Started | Owner deployment | Container definitions only |",
    "| Future presentation integrations | Deferred | Roadmap dependencies | No live-call/deepfake/bank/cybercrime claims |",
    "| Representative fraud evaluation | In Progress | Licensed representative labels | SMS spam evaluation is insufficient |",
]
write("docs/FEATURE_MATRIX.md", "\n".join(matrix))

specs = [
    "# Feature specifications",
    "",
    "Shared contract: API inputs are bounded and ownership-scoped. Mobile provides loading/error/empty states; errors never become fake success. Backend tests are distinct from device/provider acceptance.",
    "",
]
for name, screen, api, data, permission, status, checks in features:
    specs.append(f"""## {name}
1. Purpose: provide {name.lower()} within user-initiated communication analysis.
2. User story: as an account owner, I can use {name.lower()} and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/{screen} and matching backend routes; model training lives under ml/training.
4. Screens/interactions: {screen}; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: {api}.
6. Data: {data}.
7. Permissions: {permission}.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: {checks}; device acceptance tracked in TESTING.
12. Status: {status} within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.
""")
write("docs/FEATURE_SPECIFICATIONS.md", "\n".join(specs))
write(
    "docs/README.md",
    "# Documentation index\n\n"
    + "\n".join(
        f"- [{name.replace('_', ' ').title()}]({name}.md)"
        for name in sorted(
            pages.keys()
            | {
                "FEATURE_MATRIX",
                "FEATURE_SPECIFICATIONS",
                "TESTING",
                "MODEL_EVALUATION",
                "VERIFICATION_REPORT",
                "REPOSITORY_STRUCTURE",
            }
        )
    ),
)
write(
    "README.md",
    """# AI-Powered Multi-Channel Fraud Detection System
**Scan Shield** is a Flutter Android/iOS client with a FastAPI backend for user-selected SMS,
email, URL, voice transcript and call-detail analysis. It provides 0-100 risk, generic evidence,
history, in-app alerts, feedback, reports and privacy controls. No automatic inbox/call monitoring.

This is a development candidate. Rules work without provider keys. A reproducible licensed SMS
spam baseline was trained/evaluated offline and remains disabled by default; it is not validated
multi-channel fraud accuracy. Audio upload needs an approved local speech model; external
reputation and production email require configuration. See verified limitations before use.

- [Local setup](docs/DEVELOPMENT_SETUP.md)
- [Actual verification](docs/TESTING.md)
- [Feature status](docs/FEATURE_MATRIX.md)
- [Model evaluation](docs/MODEL_EVALUATION.md)
- [Credentials](docs/CREDENTIAL_SETUP.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Documentation index](docs/README.md)
- [Engineering environment](.codex/README.md)
- [Original brand guide](assets/branding/BRAND_GUIDE.md)

Run migrations before starting the API. Default local accounts allow unverified sign-in for
development only. Production mode requires PostgreSQL, email delivery and HTTPS.
No secrets, presentation identities or academic branding are included.
""",
)
print(
    "Created synchronized product, architecture, security, feature and setup documentation."
)

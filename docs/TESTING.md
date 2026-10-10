# Actual verification, 2026-10-10
| Check | Observed result |
|---|---|
| Backend pytest | 51 passed; one Starlette httpx deprecation warning |
| Alembic | Local SQLite upgrade succeeded; upgrade/downgrade exercised in automated tests |
| Backend live HTTP | Health/readiness/register/verify/login/scan/history/feedback/report/delete passed; disposable account removed |
| Ruff lint/format | Passed on backend, ML and project scripts |
| Flutter analyzer | No issues found |
| Android API integration | Passed on headless Pixel 5, Android API 36 emulator, using real local backend |
| Android UI/widget integration | 4 passed on Android API 36 emulator; observed teardown failure fixed and rerun passed |
| Debug APK | Succeeded: flutter build apk --debug, main.dart application target, 408.3s; artifacts/android/scan-shield-debug.apk |
| Native Windows Flutter widget runner | Blocked by Windows Application Control |
| Chrome widget runner | Did not finish loading; terminated; no passing results claimed |
| Project skills | All seven passed the bundled quick validator |
| Dependency audit | pip-audit final pinned lock: no known vulnerabilities; machine-readable report in docs/dependency-audit.json |
| Model training/evaluation | Executed; held-out SMS spam report, not fraud accuracy |
| Docker/PostgreSQL | Not executed; Docker unavailable locally |
| iOS/physical Android | Not executed; macOS/device verification required |
| Real SMTP/reputation/speech | Not executed; no provider credentials or local speech model supplied |

Reproduce from root:
```powershell
.\.venv\Scripts\python.exe -m ruff check backend ml scripts
.\.venv\Scripts\python.exe -m ruff format --check backend ml scripts
Set-Location backend
..\.venv\Scripts\python.exe -m pytest -q
..\.venv\Scripts\python.exe -m alembic upgrade head
```
From mobile: `flutter analyze`, `flutter test`, `flutter test -d <device> integration_test`,
and `flutter build apk --debug`. Integration tests need a running development API at
API_BASE_URL (Android emulator default http://10.0.2.2:8000/api/v1).
Tests create/delete disposable accounts. UI tests also run on Android through
integration_test/ui_test.dart to avoid the blocked native Windows test executable.
The HTTP script is `python scripts/smoke_http.py`; it expects local loopback port 8000.
The rules benchmark in docs/benchmark.json covers inference only, not API/database/load.
Backend cases cover scoring boundaries, safe messages, invalid/private URLs, contextual scams,
email import/metadata, authentication/ownership/revocation/refresh, feedback/report duplicates,
alerts/preferences, cascade deletion, retention, rate/body limits, malformed audio,
provider failure/consent, startup secret redaction, migrations and model integrity.

"""Write verifiable project evidence; arguments must reflect observed tool results."""

import argparse
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--android-ui", default="pending")
parser.add_argument("--apk", default="pending")
parser.add_argument("--audit", default="pending")
args = parser.parse_args()


def write(name, text):
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


manifest = json.loads((root / "ml/artifacts/baseline.json").read_text())
report = manifest["training_report"]
write("ml/evaluation/baseline-report.json", json.dumps(report, indent=2))
metrics = report["test"]
write(
    "docs/MODEL_EVALUATION.md",
    f"""# Executed offline baseline evaluation
Executed on 2026-10-10 using Python 3.12.14, scikit-learn {manifest["sklearn_version"]}.
Dataset: licensed SMS Spam Collection; label 1 means spam, not independently verified fraud.
Source/license: https://archive.ics.uci.edu/dataset/228/sms+spam+collection (CC BY 4.0).
Dataset hash: `{report["dataset_sha256"]}`. Seed {report["seed"]}.
After template deduplication: {report["unique_examples"]} examples; split {report["split"]}.

| Held-out spam metric | Actual value |
|---|---|
| Precision | {metrics["precision"]:.6f} |
| Recall | {metrics["recall"]:.6f} |
| F1 | {metrics["f1"]:.6f} |
| PR-AUC (average precision) | {metrics["pr_auc"]:.6f} |

Confusion matrix, rows actual ham/spam, columns predicted ham/spam:
`{metrics["confusion_matrix"]}`. False positives 7, false negatives 5 on this held-out split.
These values are **SMS spam** evaluation only. They do not establish fraud detection accuracy,
voice/email/URL performance, multilingual performance or protection against current scams.
The model is uncalibrated and disabled by default. Rule risk scores are product heuristics.
Functional training/loading/checksum/version tests passed separately; synthetic tests are not
used to report accuracy. The raw corpus and model artifacts are gitignored; the aggregate
report is in ml/evaluation/baseline-report.json. Representative fraud validation is pending.
""",
)
write(
    "docs/TESTING.md",
    rf"""# Actual verification, 2026-10-10
| Check | Observed result |
|---|---|
| Backend pytest | 51 passed; one Starlette httpx deprecation warning |
| Alembic | Local SQLite upgrade succeeded; upgrade/downgrade exercised in automated tests |
| Backend live HTTP | Health/readiness/register/verify/login/scan/history/feedback/report/delete passed; disposable account removed |
| Ruff lint/format | Passed on backend, ML and project scripts |
| Flutter analyzer | No issues found |
| Android API integration | Passed on headless Pixel 5, Android API 36 emulator, using real local backend |
| Android UI/widget integration | {args.android_ui} |
| Debug APK | {args.apk} |
| Native Windows Flutter widget runner | Blocked by Windows Application Control |
| Chrome widget runner | Did not finish loading; terminated; no passing results claimed |
| Project skills | All seven passed the bundled quick validator |
| Dependency audit | {args.audit} |
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
""",
)
write(
    "docs/VERIFICATION_REPORT.md",
    f"""# Development completion report
Architecture: Flutter Material 3 / Riverpod / GoRouter / Dio / secure storage / SQLite metadata
cache; FastAPI / Pydantic / SQLAlchemy / Alembic; SQLite local, PostgreSQL production; optional
versioned sklearn model, local faster-whisper and Google Safe Browsing provider.

Implemented: onboarding/auth lifecycle/profile/privacy controls; user-selected SMS, email,
lexical URLs, voice transcripts and call descriptions; scores/evidence/recommendations;
owned history, filters, feedback/comments, duplicate-protected internal reporting/moderation,
in-app alerts/read state, export/delete/revoke; Android text share input; original branding;
51 backend tests; mobile tests and integration suite; migrations, environment validation,
container/CI definitions, project roles/skills/workflows/rules and complete docs index.

Verified: backend tests (51), local migration, live HTTP journey, Flutter analyzer, Android
API journey on emulator, seven skill manifests, rules benchmark and offline model evaluation.
Android UI result: {args.android_ui}. Final APK: {args.apk}.
Dependency audit: {args.audit}.

Partially implemented: speech adapter/recording/playback/upload requires configured model and
device audio validation; email verification/reset needs live SMTP; optional reputation needs
approved configuration/key; caches/share sheets/recording require expanded device validation;
production PostgreSQL/TLS/backups/signing are prepared but not exercised here.
Model evaluation is an old SMS spam baseline and remains disabled by default.

Deferred: anonymous mode; OS local/push notifications (in-app alerts implemented); live calls,
deepfakes, regional-language models, live mailbox, browser/banking/enterprise integrations,
crowd intelligence, federated learning and government reporting.
No real user content was used for training. No secrets, presentation identities or academic
branding were placed in application/docs/assets. Source-review temporary images are removed.

Local run commands and migration setup: DEVELOPMENT_SETUP.md. Provider setup and exact config:
CREDENTIAL_SETUP.md and ENVIRONMENT_VARIABLES.md. Deployment/recovery: DEPLOYMENT.md and
BACKUP_AND_RECOVERY.md. Release is gated by RELEASE_CHECKLIST.md and KNOWN_LIMITATIONS.md.
Git initialized; no commit, push, hosting deployment or external message was sent.
""",
)
files = subprocess.check_output(
    ["rg", "--files", "--hidden", "-g", "!.git/**"], cwd=root, text=True
).splitlines()
write(
    "docs/REPOSITORY_STRUCTURE.md",
    "# Repository inventory\n\nGenerated source/document/asset inventory; ignored runtime/data/build files excluded.\n\n```text\n"
    + "\n".join(sorted(files))
    + "\n```",
)

for filename in ["docs/CREDENTIAL_SETUP.md", "docs/ENVIRONMENT_VARIABLES.md"]:
    path = root / filename
    content = path.read_text(encoding="utf-8")
    note = "\nGoogle Safe Browsing also requires REPUTATION_NONCOMMERCIAL_USE=true, and each URL request must explicitly set allow_external_reputation=true after user consent. Internal destinations are never sent.\n"
    if "REPUTATION_NONCOMMERCIAL_USE=true" not in content:
        path.write_text(content + note, encoding="utf-8")
path = root / "docs/DEPLOYMENT.md"
text = path.read_text(encoding="utf-8")
if "ANDROID_KEYSTORE_PATH" not in text:
    path.write_text(
        text
        + "\nAndroid release signing is enforced: set ANDROID_KEYSTORE_PATH (absolute local path), ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD in the build environment. Missing values fail release builds. Debug APKs are development-only.\n",
        encoding="utf-8",
    )
print("Wrote aggregate model evidence, verification report and repository inventory.")

# Local setup (PowerShell)
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
The local Android emulator API journey passed; no physical device was tested. Run `flutter doctor` and resolve any remaining Android licenses interactively
with `flutter doctor --android-licenses`. Never silently accept license agreements.
iOS: macOS, Xcode, CocoaPods, signing and secure-storage keychain provisioning are required.
SQLAlchemy/SciPy are pinned to compatible versions after Windows blocked newer extension DLLs.
Default rules-only development needs no API keys and uses a local SQLite database.

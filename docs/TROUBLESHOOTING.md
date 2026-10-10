# Troubleshooting
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

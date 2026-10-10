# Android development build

`scan-shield-debug.apk` is a development APK built from `mobile/lib/main.dart`, not an integration-test APK. It is ignored by Git.

The default API is `http://10.0.2.2:8000/api/v1`, which connects an Android emulator to the host's local backend. Start the backend using `docs/DEVELOPMENT_SETUP.md` before scanning or signing in.

For a physical device, rebuild from `mobile` with a reachable trusted development API:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://<development-host>:8000/api/v1
```

Debug signing and cleartext traffic are for local development. Store distribution requires owner signing, HTTPS and the release checks in `docs/RELEASE_CHECKLIST.md`.

The final artifact digest and observed checks are recorded in `docs/VERIFICATION_REPORT.md`.

Final application APK SHA-256:
`AFC85E3D2E4BF2010E61E31F2118311C2460174A245293245146C77A9C283EA9`.

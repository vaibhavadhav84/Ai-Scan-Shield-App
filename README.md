# AI-Powered Multi-Channel Fraud Detection System
**Scan Shield** is a Flutter Android/iOS client with a FastAPI backend for user-selected SMS,
email, URL, voice transcript and call-detail analysis. It provides 0-100 risk, generic evidence,
history, in-app alerts, feedback, reports and privacy controls. No automatic inbox/call monitoring.

This is a development candidate. Rules work without provider keys. A reproducible licensed SMS
spam baseline was trained/evaluated offline and remains disabled by default; it is not validated
multi-channel fraud accuracy. Audio upload needs an approved local speech model; external
reputation and production email require configuration. See verified limitations before use.

- [Local setup](docs/DEVELOPMENT_SETUP.md)
- [Actual verification](docs/TESTING.md)
- [Development Android APK](artifacts/android/scan-shield-debug.apk) and [build notes](artifacts/android/README.md)
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

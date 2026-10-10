# Trusted artifacts
Training saves `baseline.joblib` and `baseline.json` with schema, library version, SHA-256 and
evaluation report. Both files are gitignored. Never load artifacts uploaded by an end user:
joblib can execute code. Set MODEL_PATH only to a trusted administrator-provisioned artifact.
Empty MODEL_PATH selects explicit rules only. No automatic model download or retraining occurs.

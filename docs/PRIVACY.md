# Privacy specification - deployment owner review required
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

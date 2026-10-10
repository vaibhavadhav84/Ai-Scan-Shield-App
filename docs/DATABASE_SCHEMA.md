# Data model
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

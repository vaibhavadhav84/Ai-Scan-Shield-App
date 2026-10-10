# Security controls
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

# API reference
FastAPI OpenAPI: `/openapi.json`; interactive docs: `/docs`. Routes are `/api/v1`.
JSON errors use `detail`; 401 session invalid, 403 admin/verification, 404 unowned/not found,
409 duplicate account/report, 413 body too large, 422 invalid input, 429 throttled, 503 provider.
Use `Authorization: Bearer <access_token>` for authenticated endpoints.

| Group | Routes |
|---|---|
| Auth | POST /auth/register, /login, /refresh, /logout, /revoke-all |
| Email actions | POST /auth/verification/request, /confirm; /auth/password/request, /confirm |
| Account | GET/PATCH/DELETE /users/me; GET /users/me/export |
| Scans | POST/GET/DELETE /scans; GET /scans/summary; GET/DELETE /scans/{id} |
| Imports | POST /scans/voice (multipart PCM WAV); /scans/email-file (.eml) |
| Feedback | PUT /scans/{id}/feedback |
| Reports | POST/GET /reports |
| Alerts | GET /alerts; PATCH /alerts/{id}/read |
| Admin | GET /admin/metrics, /admin/reports; PATCH /admin/reports/{id} |
| Availability | GET /capabilities; /health and /ready outside version prefix |

Example scan JSON: `{"channel":"sms","content":"Send your OTP immediately."}`.
Email optionally adds sender, reply_to, subject and attachment_names. Call accepts contextual
phone_number without phone reputation. A scan result contains id/channel/time, score/risk,
summary, indicators (code/title/points/evidence), recommendations, versions and limitations.
Voice immediately adds transcript, which is absent from persisted history.
History query: channel, risk, start/end Unix seconds, search (ID only), offset, limit 1-100.
Feedback verdict: correct, false_positive, missed_scam, uncertain. Reports category:
credentials, payment, impersonation, investment, other. Moderation: reviewed/dismissed/escalated.
Registration password minimum 12; login max 128. Reset accepts token plus new password.
Development registration may return development_token; production sends only via SMTP.
Reset never exposes tokens to unauthenticated callers. No automatic URL opening endpoint exists.

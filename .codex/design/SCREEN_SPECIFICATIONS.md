# Screen inventory and target hierarchy
| Route/state | Implemented structure and behavior to preserve |
|---|---|
| Native splash | Original shield, quiet canvas; native launch assets retained |
| /onboarding | Brand illustration, concise channel/value explanation, privacy/interpretation, get started/skip/help |
| /auth | Separate sign-in/create/verify/reset views within existing route; labeled fields, visibility, busy/validation/recovery |
| /home | Context header, dominant scan CTA, channel tiles, real recent history/summary, alerts and boundaries |
| /scan SMS | Channel selector, focused multiline input, paste/clear, count, consent/privacy, actual submit state |
| /scan email | Optional metadata separated from required body, .eml import and filename-only attachment limitation |
| /scan URL | Nonclickable domain preview, valid full URL, explicit optional provider consent, no auto navigation |
| /scan voice | Permission explanation, real elapsed time and record/stop/play/delete/upload, transcript alternative |
| /scan call | Description plus optional number; no caller identity claim |
| /result/:id | Compact score band, real recommendation, evidence, other precautions, provider/limits, feedback/report/export/delete |
| /history | Search/filter controls in scrollable layout, metadata rows, clear confirmation, pagination, empty/offline states |
| /alerts | Read/unread text and treatment, actual severity, mark read and related result |
| /reports | Category/status/timestamp, internal-review explanation, result navigation and pagination |
| /profile | Account, appearance/alerts, data/privacy, session/account actions grouped clearly |
| /help | Readable accordion guidance, permissions/privacy/terms/provider limits and scam education |
| Initialization error | Branded recoverable storage-error state and retry |

Provider-dependent voice/SMTP/reputation remain unverified; redesign does not change feature availability.

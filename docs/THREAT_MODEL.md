# Threat model
Assets: passwords, sessions, account email, private submitted content, scores, report comments,
provider keys and trusted model artifacts. Trust boundaries: device/API, API/database,
API/SMTP/reputation, uploaded audio decoder and model provisioning.

| Threat | Control | Residual risk / release action |
|---|---|---|
| Account compromise | Argon2; token hashes/rotation/expiry/revocation; throttling | Add MFA and distributed account abuse review |
| Cross-user access | Every record query scopes owner; 404 for unowned IDs | Exercise PostgreSQL concurrency before release |
| Malicious URL / SSRF | Parse only; fixed provider host; no DNS or redirects | Lexical rules cannot establish website safety |
| Malicious upload | Pre-parser size cap; PCM WAV parameters; plain-text .eml only | Isolate speech decoder in restricted worker before broad public service |
| Injection/model manipulation | Deterministic templates; no LLM tools; bound input | Evasion and adversarial phrasing remain possible |
| Artifact execution | Administrator-only path, hash and library version | joblib remains executable; trusted provisioning required |
| Privacy leakage | No raw history; generic evidence; redacted errors/logs; deletion | Backups, shared-device caches and owner policies require review |
| False positives/negatives | Context pairs, limitations, feedback; explicit unvalidated baseline | Representative fraud evaluation pending |
| Denial of service | Request/rate/audio bounds; provider timeouts | Gateway concurrency and CPU budgets required for speech |
| Admin misuse | Protected aggregates/redacted reports; audit moderation | Operational review of least privilege required |

No automatic SMS/call access, mailbox OAuth, deepfake claims or banking authority.
Use HTTPS, private database network, restricted containers, secret manager and protected backups.

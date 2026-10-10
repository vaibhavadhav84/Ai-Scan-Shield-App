# Known limitations
English contextual rules can be evaded, miss scams and flag legitimate requests. Unicode is
preserved but regional-language modeling is not validated. Initial risk thresholds are product
heuristics, not calibrated fraud probabilities. No assurance of safety is provided.
Offline SMS spam model evaluation does not validate multi-channel fraud detection; model is
disabled by default. No automatic inbox/call access, mailbox OAuth, real-time analysis, sender
authentication, SPF/DKIM/DMARC validation, phone intelligence or deepfake detection.
URLs are never visited; no live certificate/domain age/redirect/DNS analysis. Optional reputation
requires approved noncommercial configuration; no live API key test has run.
Only PCM WAV, max 10 MB/180s; no speech model bundled; no live transcription/device microphone
verification. Local and push notifications beyond in-app alert records are not implemented.
Anonymous scanning is not enabled. Feedback verdicts and optional comments are implemented in the API and mobile UI; device validation of the comments dialog remains pending.
Offline history is metadata only, has a 24-hour display limit, and cannot perform new scans.
No production hosting, backup restore, legal review or store signing is done. Android text sharing and secure storage are implemented; the real-backend account journey passed on an emulator. Physical-device recording, sharing and export validation remains pending.
See TESTING.md and FEATURE_MATRIX.md for actual command outcomes and outstanding build gates.

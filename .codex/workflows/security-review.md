# security-review
Inputs: Changed API, trust boundaries and threat model.
Steps: Check auth, token expiry, isolation, uploads, SSRF avoidance, rate limits, redaction, deletion.
Validation: Adversarial tests exercise each control.
Outputs: Findings, fixes and residual risks.
Failure handling: retain diagnostics without secrets, fix reproducible failures, mark external blockers accurately; do not fabricate success.

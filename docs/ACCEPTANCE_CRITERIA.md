# Acceptance criteria
Register/login, verify once, refresh rotation, revoke, reset and deletion must preserve identity
boundaries. Passwords/tokens must be hashes; validation must not echo secrets.
Suspicious SMS must yield a real result with 0-100 score, appropriate level, evidence and limits;
ordinary OTP notices/protective instructions must not be flagged by a keyword alone.
Saved results must be retrievable only by owner; feedback/report submission must persist and
reject duplicate reports; deleting a scan must cascade related records.
URL schemes/hosts must be validated without target requests; provider failures must disclose
lexical-only limitations. EML must never run scripts/attachments; malformed WAV must fail before
decoding; missing speech config must be explicit; transcripts must not persist.
Alert preference must suppress new records. History must paginate/filter and have empty/error
states. All sensitive actions must handle API failures without fabricated success.
Mobile must pass analyzer/widget/navigation/repository tests, build and complete device journeys
before release. Backend must start after migrations and pass ownership/upload/retention/ML tests.
External providers require actual credentialed verification. Model accuracy claims require
representative held-out fraud data; spam-baseline results do not satisfy that release gate.

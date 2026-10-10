# Product requirements
Primary functional reference: supplied 23-page presentation, including image-based tables on
pages 13-20. Only technical requirements are recorded. The pasted master prompt expands its
scope with privacy, authentication lifecycle, deployment and quality requirements.

| Source ID | Requirement | Implementation boundary |
|---|---|---|
| FR1 | Registration/login | Argon2, revocable sessions, verification/reset tokens |
| FR2 | SMS analysis | Manually submitted text; contextual English rules |
| FR3 | Email analysis | Sender/reply-to, subject/body, .eml and attachment filenames |
| FR4 | URL analysis | Parsing and lexical indicators; optional fixed reputation API |
| FR5 | Voice analysis | PCM WAV upload, local speech adapter, transcript rules |
| FR6 | Classification | Safe / Suspicious / High Risk |
| FR7 | Risk score | Integer 0-100, configurable boundaries 30/70 |
| FR8 | Alerts | Preference-aware in-app records and read state |
| FR9 | Explanations | Structured evidence, score rationale, next actions, limitations |
| FR10 | History | Ownership, pagination, filters, ID search, deletion/export |
| FR11 | Feedback | Four verdicts; optional API comments, controlled future training |
| FR12 | Scam reporting | Duplicate prevention, internal moderation and audit |

NFRs: performance (bounded input, benchmark); security (ownership and abuse tests); privacy
(metadata-only history and retention); accuracy (held-out spam baseline, fraud validation pending);
scalability (PostgreSQL extension, deployment load checks pending); availability (health/readiness,
backups); usability (Material 3, states and accessibility tests); maintainability (modules and CI);
reliability (deterministic regression corpus); explainability (evidence-linked scores).
No guarantee of protection. Source future scope remains deferred: regional language modeling,
deepfakes, live calls, browser/banking/enterprise integrations, crowd intelligence, federated
learning and government reporting. Calls use manually supplied descriptions only.

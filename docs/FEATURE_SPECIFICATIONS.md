# Feature specifications

Shared contract: API inputs are bounded and ownership-scoped. Mobile provides loading/error/empty states; errors never become fake success. Backend tests are distinct from device/provider acceptance.

## Onboarding
1. Purpose: provide onboarding within user-initiated communication analysis.
2. User story: as an account owner, I can use onboarding and understand its limitations.
3. Functional behavior: three onboarding explanations introduce channels, privacy and fallibility. Get started/skip persist local completion and navigate to authentication; help is accessible before sign-in.
4. Screens/interactions: onboarding; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: None during onboarding; subsequent authentication uses /api/v1/auth.
6. Data: Local completion preference.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: Android onboarding-to-sign-in navigation passed; physical-device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Accounts
1. Purpose: provide accounts within user-initiated communication analysis.
2. User story: as an account owner, I can use accounts and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/authentication and matching backend routes; model training lives under ml/training.
4. Screens/interactions: authentication; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /auth/*, /users/me.
6. Data: users, sessions, action_tokens.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: authentication/reset/revocation tests; SMTP/device pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Home
1. Purpose: provide home within user-initiated communication analysis.
2. User story: as an account owner, I can use home and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/dashboard and matching backend routes; model training lives under ml/training.
4. Screens/interactions: dashboard; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans/summary, /scans, /capabilities.
6. Data: Read owned scans.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: summary API; widget/device pending; device acceptance tracked in TESTING.
12. Status: Implemented within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## SMS/text
1. Purpose: provide sms/text within user-initiated communication analysis.
2. User story: as an account owner, I can use sms/text and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/scan and matching backend routes; model training lives under ml/training.
4. Screens/interactions: scan; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans.
6. Data: scans, alerts.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: contextual rules + end-to-end API; device pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Email
1. Purpose: provide email within user-initiated communication analysis.
2. User story: as an account owner, I can use email and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/scan and matching backend routes; model training lives under ml/training.
4. Screens/interactions: scan; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans, /scans/email-file.
6. Data: scans, alerts.
7. Permissions: System file picker.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: metadata/import tests; device pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## URL
1. Purpose: provide url within user-initiated communication analysis.
2. User story: as an account owner, I can use url and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/scan and matching backend routes; model training lives under ml/training.
4. Screens/interactions: scan; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans.
6. Data: scans, alerts.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: parsing/private destination/provider failure tests; live key pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Voice
1. Purpose: provide voice within user-initiated communication analysis.
2. User story: as an account owner, I can use voice and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/scan and matching backend routes; model training lives under ml/training.
4. Screens/interactions: scan; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans/voice or /scans.
6. Data: scans; temporary WAV deleted.
7. Permissions: Microphone only on recording.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: invalid/missing-provider/mock-transcript tests; local model not provided; device acceptance tracked in TESTING.
12. Status: Blocked within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Call details
1. Purpose: provide call details within user-initiated communication analysis.
2. User story: as an account owner, I can use call details and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/scan and matching backend routes; model training lives under ml/training.
4. Screens/interactions: scan; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans.
6. Data: scans, alerts; phone not retained.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: text engine reused; caller not authenticated; device acceptance tracked in TESTING.
12. Status: Implemented within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Results
1. Purpose: provide results within user-initiated communication analysis.
2. User story: as an account owner, I can use results and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/results and matching backend routes; model training lives under ml/training.
4. Screens/interactions: results; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans/{id}.
6. Data: Read scan metadata.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: score/risk/evidence API; UI/device pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## History
1. Purpose: provide history within user-initiated communication analysis.
2. User story: as an account owner, I can use history and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/history and matching backend routes; model training lives under ml/training.
4. Screens/interactions: history; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans, /scans/{id}.
6. Data: scans; metadata cache.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: ownership/filter/deletion/retention API; cache/device pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Alerts
1. Purpose: provide alerts within user-initiated communication analysis.
2. User story: as an account owner, I can use alerts and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/reports and matching backend routes; model training lives under ml/training.
4. Screens/interactions: reports; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /alerts.
6. Data: alerts.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: preference/read-state API; no OS notifications; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Feedback
1. Purpose: provide feedback within user-initiated communication analysis.
2. User story: as an account owner, I can use feedback and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/results and matching backend routes; model training lives under ml/training.
4. Screens/interactions: results; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /scans/{id}/feedback.
6. Data: feedback.
7. Permissions: None.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: verdict/comment persistence + ownership API tests; optional mobile comment dialog implemented, device validation pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Reports/admin
1. Purpose: provide reports/admin within user-initiated communication analysis.
2. User story: as an account owner, I can use reports/admin and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/reports and matching backend routes; model training lives under ml/training.
4. Screens/interactions: reports; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /reports, /admin/*.
6. Data: reports, audit_events.
7. Permissions: Admin server role for review.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: duplicate/ownership/admin API; operational review pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Profile/privacy
1. Purpose: provide profile/privacy within user-initiated communication analysis.
2. User story: as an account owner, I can use profile/privacy and understand its limitations.
3. Functional behavior: implemented code in mobile/lib/features/account and matching backend routes; model training lives under ml/training.
4. Screens/interactions: account; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: /users/me, /users/me/export.
6. Data: users and cascading children.
7. Permissions: Share sheet for export.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: export/account deletion/retention API; device export pending; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

## Model training
1. Purpose: provide model training within user-initiated communication analysis.
2. User story: as an account owner, I can use model training and understand its limitations.
3. Functional behavior: offline CLI in ml/training/train.py normalizes and deduplicates licensed examples, partitions training/validation/test data, fits TF-IDF/logistic regression and emits held-out metrics plus a versioned artifact. No mobile training screen or public training endpoint exists.
4. Screens/interactions: ml/training; submit/select/read/confirm as appropriate; risk actions originate on results.
5. API: No public training endpoint.
6. Data: Trusted versioned artifact, no private submissions.
7. Permissions: Administrator provisioning.
8. Security/privacy: current-user scope; no raw scan storage; no automatic URL/file execution; comments are explicitly stored.
9. Errors: validated 4xx input/ownership/session errors; 503 missing providers; mobile retry and bounded timeouts; no invented outcomes.
10. Dependencies: configured API; optional SMTP/speech/reputation only where applicable, see CREDENTIAL_SETUP.
11. Verification: held-out SMS spam baseline, functional model loading/hash test; device acceptance tracked in TESTING.
12. Status: Tested within the evidence scope above.
13. Limitations: see KNOWN_LIMITATIONS; no guarantee of detection accuracy, identity validation or automatic monitoring.

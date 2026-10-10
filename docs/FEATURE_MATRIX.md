# Feature status and evidence

Statuses apply to the indicated scope; Tested API does not mean mobile/device/provider validation.

| Feature | Status | Platform / dependency | Evidence and limitation |
|---|---|---|---|
| Onboarding | Tested | Flutter; None | Android first-use navigation test passed; physical-device acceptance pending |
| Accounts | Tested | Flutter/API; None | backend auth/reset/revocation plus real-backend Android sign-in/account-delete journey; live SMTP and physical-device pending |
| Home | Implemented | Flutter/API; None | summary API; widget/device pending |
| SMS/text | Tested | Flutter/API; None | contextual rules + real-backend Android API journey; complete scan-screen UI and physical-device acceptance pending |
| Email | Tested | Flutter/API; System file picker | metadata/import tests; device pending |
| URL | Tested | Flutter/API; None | parsing/private destination/provider failure tests; live key pending |
| Voice | Blocked | Flutter/API; Microphone only on recording | invalid/missing-provider/mock-transcript tests; local model not provided |
| Call details | Implemented | Flutter/API; None | text engine reused; caller not authenticated |
| Results | Tested | Flutter/API; None | score/risk/evidence API; Android risk-label/icon/contrast test passed; complete result-screen journey pending |
| History | Tested | Flutter/API; None | ownership/filter/deletion/retention API; cache/device pending |
| Alerts | Tested | Flutter/API; None | preference/read-state API; no OS notifications |
| Feedback | Tested | Flutter/API; None | verdict/comment persistence + ownership API; mobile comments dialog implemented, device validation pending |
| Reports/admin | Tested | Flutter/API; Admin server role for review | duplicate/ownership/admin API; operational review pending |
| Profile/privacy | Tested | Flutter/API; Share sheet for export | export/account deletion/retention API; device export pending |
| Model training | Tested | Flutter/API; Administrator provisioning | held-out SMS spam baseline, functional model loading/hash test |
| Local/push notifications | Deferred | Selected service + runtime consent | In-app alerts only |
| Anonymous mode | Deferred | Abuse/privacy design | Sign-in required |
| Store release/iOS builds | Blocked | Signing, device/macOS | No store release |
| Production hosting/backups | Not Started | Owner deployment | Container definitions only |
| Future presentation integrations | Deferred | Roadmap dependencies | No live-call/deepfake/bank/cybercrime claims |
| Representative fraud evaluation | In Progress | Licensed representative labels | SMS spam evaluation is insufficient |

# Scan Shield design review — 2026-10-10

Direction: **Quiet Security**, with approachable channel actions and evidence-led results.
The three alternatives and internal comparison are in `.codex/design/DESIGN_BRIEF.md`.
These are engineering/design judgments, not findings from recruited user research.

## Pass 1 — Task flow and consistency

The original app's real backend contracts, user isolation, original branding and data controls were retained.
The review identified undifferentiated screen stacks, crowded authentication, a disproportionately large
result gauge, fixed history filters, lost drafts between tabs, and weak recovery hierarchy.

Changes integrated:
- Shared light/dark semantic tokens, type, surface, shape and control themes.
- Focused sign-in, registration, verification and recovery states with validation and password visibility.
- Dominant home scan action, meaningful channel tiles and actual recent activity.
- Separate memory-only channel drafts, paste/clear, safe domain preview and honest voice elapsed time.
- Compact result score, first server recommendation, expandable actual evidence and unavailable-check labels.
- Feedback/report dialogs retain input after network failures and close after successful acknowledgement.
- Scrollable history filters, readable report/alert states, grouped settings and visible privacy controls.
- Stateful tab navigation; API panels refresh on navigation identity rather than unrelated local rebuilds.
- Branded loading, empty, error and success treatments, with no production fixtures or fabricated progress.

The initial formatting pass exposed eight legacy-encoded source bytes in the scan screen; these were
normalized to UTF-8. Analyzer findings are being resolved before final acceptance.

## Pass 2 — Rendered quality and interaction

In progress. The Android run captures real Flutter renders of explicitly labeled test-fixture states.
Fixtures are confined to `mobile/test/support/design_fixtures.dart`; no preview data enters production UI.
Rendered inspection, corrective changes and final test counts will be recorded here when observed.

## Verification scope

Backend regression: **51 passed**, one existing Starlette/httpx deprecation warning.
Flutter screen/layout/accessibility suite and real-backend Android journey: running; no pass claimed yet.
New design skill manifests: validation recorded separately at finalization.

Physical devices, iOS/macOS, live SMTP/reputation/speech providers, TalkBack and VoiceOver are separate
acceptance work. Semantic and contrast tests alone do not establish complete assistive-technology support.
No golden-image baseline existed before this change; captures support visual review, not an established
pixel-diff regression claim.

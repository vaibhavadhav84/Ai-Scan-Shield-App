# Scan Shield design review — started 2026-10-10, continued 2026-10-20

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
normalized to UTF-8. Flutter analysis passes after the interaction corrections.

Follow-up corrections on October 20:
- Incoming shared text asks before replacing a nonempty SMS draft.
- Recording observes route coverage and app lifecycle; a late permission result cannot start it offscreen.
- Recovery navigation preserves the entered email and clears password input.
- Account deletion shows a required-password error and gives the dialog ownership of its controller.
- Retry immediately shows pending state instead of retaining the previous error button.
- Timeout and oversized-file errors give specific recovery guidance.

## Pass 2 — Rendered quality and interaction

In progress. The Android run captures real Flutter renders of explicitly labeled test-fixture states.
Fixtures are confined to `mobile/test/support/design_fixtures.dart`; no preview data enters production UI.
Rendered inspection, corrective changes and final test counts will be recorded here when observed.

## Verification scope

Backend regression on October 20: **51 passed**, one existing Starlette/httpx deprecation warning.
Flutter analyzer: **no issues found**. The first Android run passed the real-backend journey and four
existing app checks, then stalled in the native Android screenshot callback. That run was stopped.
The harness now uses Flutter's actual RepaintBoundary render output at the requested test viewport,
transferred through the integration driver. It does not capture Android system bars or native dialogs.
The full screen/layout/accessibility suite is rerunning; no complete-suite pass is claimed yet.
New design skill manifests: validation recorded separately at finalization.

Physical devices, iOS/macOS, live SMTP/reputation/speech providers, TalkBack and VoiceOver are separate
acceptance work. Semantic and contrast tests alone do not establish complete assistive-technology support.
No golden-image baseline existed before this change; captures support visual review, not an established
pixel-diff regression claim.

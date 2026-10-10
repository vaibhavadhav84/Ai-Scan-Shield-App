"""Create the requested design playbooks without replacing existing engineering files."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def add(relative, content):
    path = ROOT / ".codex" / relative
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite existing design file: {relative}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


roles = {
    "product_design_director": ("Choose hierarchy, product direction and acceptance scope", "design/DESIGN_BRIEF.md, DESIGN_DECISIONS.md and review records", "audit, requirements and rendered screens", "direction, prioritized review and evidence-scoped acceptance"),
    "mobile_ux_researcher": ("Audit routes, recovery and consumer comprehension without inventing research", "design/SCREEN_SPECIFICATIONS.md and INTERACTION_SPECIFICATIONS.md", "working screens, API contracts and limitations", "task flows, friction findings and observable acceptance cases"),
    "visual_design_specialist": ("Apply restrained visual hierarchy and original existing branding", "design color/type/layout documents and existing branding integration", "selected direction and shared theme", "consistent light/dark compositions and annotated visual findings"),
    "design_system_architect": ("Own semantic tokens and reusable component contracts", "mobile/lib/shared/design.dart, widgets.dart and design system catalog", "screen requirements and accessibility constraints", "theme, components and documented variants"),
    "flutter_ui_engineer": ("Implement assigned presentation modules while preserving real API flows", "assigned mobile/lib/features files and associated widget tests", "tokens, component contracts and current implementation", "working responsive screens with failure and busy states"),
    "accessibility_specialist": ("Review contrast, targets, semantics, focus, scaling and reduced motion", "accessibility standards and assigned tests; coordinate source fixes with owner", "rendered screens, semantic tree and test results", "reproducible findings and verified corrections"),
    "interaction_motion_designer": ("Make progress, focus and state transitions understandable", "interaction/motion specifications and assigned presentation widgets", "actual request and recording states", "short nonblocking transitions with reduced-motion handling"),
    "design_qa_reviewer": ("Inspect rendered output and validate behavior across themes and sizes", "mobile/test, mobile/integration_test and docs/DESIGN_REVIEW.md", "final screens, test fixtures and device capabilities", "two review passes, screenshots and actual test evidence"),
}
for name, (role, files, inputs, outputs) in roles.items():
    add(f"agents/{name}.md", f"""# {name.replace('_', ' ').title()}
Role and responsibilities: {role}.
Editable scope: {files}. Respect explicit per-agent ownership; do not modify another agent's files concurrently.
Inputs: {inputs}. Outputs: {outputs}.
Standards: read ../design/DESIGN_PRINCIPLES.md and the relevant specification. Preserve risk meaning,
provider absence, privacy and existing routing/API contracts. Use shared tokens; no production fixtures.
Collaboration: report concrete findings to the coordinating agent; agree component interfaces before parallel edits.
Validation: static checks plus relevant behavior tests and actual rendered inspection; record unavailable checks.
Done: scoped files integrated, defects addressed and evidence/limitations recorded. This Markdown is a role
contract; only the runtime collaboration tools launch real subagents.
""")

skills = {
    "mobile-product-design": ("Audit and redesign Scan Shield consumer mobile task flows using existing routes and real service states.", "Map entry, primary action, success, back path and recovery for each route. Inspect current implementation before choosing a pattern. Prefer one dominant action and progressive detail. Evaluate the three directions in DESIGN_BRIEF; preserve existing features and useful drafts."),
    "cybersecurity-ux": ("Design Scan Shield risk, evidence, consent and privacy communication without overstating protection.", "Trace every score, reason and provider status to its response field. Risk means a heuristic indicator, not calibrated probability. Keep Safe/Suspicious/High Risk labels, icons and explanatory copy together. Put the first real recommendation above supporting evidence. Never turn provider absence into a passed check or open submitted links."),
    "design-system-engineering": ("Extend the shared Flutter tokens and components for a consistent Scan Shield interface.", "Read DESIGN_SYSTEM and COMPONENT_CATALOG. Add a semantic token or variant before repeating inline decoration. Theme both brightness modes. Keep APIs small and use Material controls for focus, targets and semantics. Test a reused component in narrow/large-text contexts before migrating consumers."),
    "flutter-ui-excellence": ("Implement responsive Scan Shield screens using Riverpod, GoRouter and existing API clients.", "Preserve API payloads and owner-scoped operations. Hold Future loads outside rebuild loops, disable repeated actions while awaiting, and keep useful form content on errors. Use scrollable forms, constrained widths and wrap/adaptive layouts. Compile/analyze then exercise interactions on supported test runners."),
    "accessibility-and-inclusive-design": ("Review Scan Shield contrast, semantics, touch targets and large-text layouts.", "Use ACCESSIBILITY_STANDARDS. Check normal text at 4.5:1, large text/nontext controls at 3:1, and 48 logical-pixel targets. Exercise 320-wide and 2x text with keyboard insets. Validate risk labels without color. Dispose semantics handles within test bodies. Report screen-reader device checks separately from semantic tests."),
    "motion-and-microinteractions": ("Implement honest progress and restrained, accessible transitions in Scan Shield.", "Only animate state that exists: request pending, bytes uploaded, recording elapsed, received score. Do not simulate backend stages or delay results. Use 160-220ms transitions, set duration zero when disableAnimations is true, and avoid endless decorative animation. Progress must have an accessible label."),
    "visual-regression-testing": ("Capture and review actual Flutter screens across design states and record visual evidence.", "Use isolated explicit test fixtures only in test targets. Capture actual rendered screens with integration screenshots or device capture; never present fixture counts as user history. Review hierarchy and task flow first, then clipping, alignment, contrast and interaction. Record dimensions/theme/text scale. Do not claim golden regression coverage without a stored comparison baseline."),
}
for name, (description, body) in skills.items():
    add(f"skills/{name}/SKILL.md", f"""---
name: {name}
description: {description}
---

{body}

Read the relevant documents in ../../design/ before changes. These project playbooks are explicitly
referenced by AGENTS.md; the .codex/skills directory is not claimed as automatic skill discovery.
Completion requires implemented behavior, relevant verification, and updated evidence. User scope and
authorization still govern external actions; these instructions do not grant extra permission.
""")

flows = {
    "design-audit": ("Existing UI or a requested redesign", "Read screen code, requirements, API states and navigation; list implemented/blocked/deferred features", "Record strengths, friction and three visual alternatives; choose an evidence-based direction", "Every implemented route and error/empty/loading state accounted for", "An actionable inventory and selected direction exist before visual edits"),
    "design-system-creation": ("Approved direction and screen inventory", "Find existing repeated colors, type and layout patterns", "Implement semantic light/dark tokens and reusable components before consumer migration", "Contrast, semantic roles, 48px targets and scaled text", "Catalog matches actual component constructors and token source"),
    "screen-redesign": ("Known screen owner and shared component contract", "Inspect API calls, controllers, navigation, privacy and busy/error states", "Restructure hierarchy using shared components; retain working actions and add recovery", "No fake data, lost actions, duplicate requests or inaccessible controls", "Screen works with actual responses and relevant behavior tests"),
    "design-review": ("Runnable screens", "Pass 1: hierarchy/task clarity; Pass 2: actual rendered alignment and interaction", "Fix reproducible findings and capture corrected evidence", "Both themes, long content, three risk states and empty/error states", "Review record names findings, corrections and unavailable checks"),
    "responsive-ui-validation": ("Screen implementation available", "Identify fixed dimensions, nested scrolls, keyboard insets and text scaling assumptions", "Exercise 320/390/430-wide layouts, 1x/2x text and keyboard-visible forms", "No RenderFlex overflow, clipped labels or inaccessible actions", "Passing scoped layout tests and inspected images; physical-device gaps disclosed"),
    "accessibility-review": ("Components and interactive screens available", "Inspect contrast pairs, labels, focus order, control size and risk redundancy", "Run Flutter guidelines and semantics assertions; fix failures and recheck", "4.5:1 normal text, 3:1 large/nontext; 48px targets; reduced motion", "Actual checks recorded; do not equate semantics tests with full TalkBack/VoiceOver validation"),
    "final-design-acceptance": ("Integrated redesign", "Review design acceptance criteria, feature matrix and current diffs", "Format, analyze, run widget/integration/backend regression checks and build Android", "Screenshots inspected; security meaning preserved; no introduced failing checks", "Report changed files, actual checks, inspected screens and remaining dependencies"),
}
for name, (entry, inspect, implement, checks, done) in flows.items():
    add(f"workflows/{name}.md", f"""# {name.replace('-', ' ').title()}
Entry conditions: {entry}.
Inspection: {inspect}.
Implementation: {implement}.
Quality checks: {checks}.
Failure handling: keep diagnostics free of private content; fix the concrete failure, rerun its relevant
check, and mark device/provider absence explicitly. Do not fabricate screenshots or test passes.
Completion: {done}.
""")

rules = {
    "design-principles": "One obvious primary action; calm evidence-led risk communication; privacy controls remain discoverable. Follow design/DESIGN_PRINCIPLES.md.",
    "visual-consistency": "Use shared/design.dart and shared/widgets.dart. Brand blue is interaction, semantic teal/amber/red is risk. No per-screen color palettes or decorative statistics.",
    "mobile-interaction": "Keep forms scrollable above keyboard. Disable repeat submissions. Preserve drafts across app tabs; do not store raw input in persistent preferences. Confirm destructive operations with a specific action label.",
    "accessibility": "Support 2x text and 320-wide layouts. Risk uses label/icon/score. Icon actions have tooltips; controls have 48px targets. Respect disableAnimations. See design/ACCESSIBILITY_STANDARDS.md.",
    "cybersecurity-content-design": "Use actual response evidence only. Safe is not guaranteed safety. Missing checks are unavailable, never clear. State audio transmission and explicit external URL consent. No automatic scanned URL navigation.",
    "flutter-design-implementation": "Keep Riverpod/GoRouter/Dio. Reuse existing domain/API behavior. Shared theme owns color/type/shape. Isolated fixtures belong under test, never production UI. Resolve observed errors before broadening scope.",
    "design-quality-gates": "Run format, analyzer, relevant widget/integration and backend regression checks. Inspect actual renders in two review passes. Record scope and limitations; do not claim pixel-perfect or user-research validation without evidence.",
}
for name, rule in rules.items():
    add(f"rules/{name}.md", f"# {name.replace('-', ' ').title()}\n{rule}")

documents = {
    "DESIGN_BRIEF": """# Design brief and exploration
Goal: a calm consumer product that makes the next safe action clear while keeping uncertainty visible.
Audit: real API flows, privacy controls and original branding are strengths. Weaknesses: undifferentiated
stacks, crowded auth, giant result gauge, fixed history filters, limited empty/error hierarchy, no scan paste/clear,
missing password visibility and no voice elapsed time. All 11 route types and five channel states are in scope.

Scores below are internal design judgments (1-5), not user research.
| Criterion | A Quiet Security | B Intelligence Console | C Consumer Protection |
|---|---|---|---|
| Trust | 5 | 4 | 4 |
| Originality | 4 | 4 | 4 |
| Accessibility | 5 | 3 | 5 |
| Ease of use | 5 | 3 | 5 |
| Risk communication | 5 | 5 | 4 |
| Hierarchy | 5 | 4 | 4 |
| Mobile usability | 5 | 3 | 5 |
| Consistency | 5 | 4 | 4 |
| Feasibility | 5 | 4 | 5 |
| Everyday suitability | 5 | 3 | 5 |

Selected: A with C's direct channel actions and B's evidence hierarchy. Warm neutral canvas, ink blue
hero, restrained royal-blue interaction, compact semantic risk bands, readable platform typography,
outlined channel symbols and generous but purposeful grouping. No external fonts or new services.
""",
    "DESIGN_PRINCIPLES": """# Design principles
1. Lead with the user's next action, not a decorative metric.
2. Communicate risk with words, icon, numeric score and evidence. Scores are not probabilities.
3. Be precise about what was checked and what was unavailable.
4. Reveal technical and privacy detail progressively without hiding material limitations.
5. Keep the original logo, consistent tokens and platform-native readable type.
6. Preserve actual business logic, routes and security controls; test transitions and recovery.
7. Prefer a readable single column, adapting tiles and actions to available space and text scale.
""",
    "DESIGN_SYSTEM": """# Design system
Source of truth: mobile/lib/shared/design.dart (ShieldSpace, ShieldShape, ShieldPalette, shieldTheme,
RiskTone and channel metadata). shared/widgets.dart holds presentation primitives.
appTheme in app/app.dart delegates to shieldTheme, preserving the public app theme entry point.
Material 3 controls supply keyboard/focus/touch behavior. Both brightness modes have explicit semantic
surfaces, text, outline and risk pairs. No additional dependency is required.
Component contract: PageBody, PageHeading, SectionHeading, SurfaceCard, Notice with NoticeKind,
EmptyState, BusyButton, RiskBadge, RiskScore, ChannelTile, ScanTile, EvidenceTile, LoadingSkeleton,
ProcessingPanel, SettingsRow, AdaptiveActions. Existing Brand, ApiPanel, confirm, showMessage retained.
""",
    "COLOR_SYSTEM": """# Color system
Authoritative values are centralized in shared/design.dart. Brand blue: #245FD6 (light), #ABC6FF (dark).
Accent teal: #08796D / #79DACA. Canvas: #F5F7FA / #0C1725; surfaces: #FFFFFF / #142337.
Text: #142B40 / #EAF1FA; supporting: #526477 / #AFBED0. Borders: #D8E0EA / #34465B.
Hero is #142E4B with light foreground. Safe: #006B57 / #80DFC1; suspicious: #865000 / #FFD080;
high risk: #AF273D / #FFB2BC. Each risk has a paired tinted container and icon/label.
Focus uses brand blue; errors reuse high-risk semantic tone with explicit error copy; info uses blue.
Use alpha only for decorative surfaces, never to reduce essential text below contrast targets.
""",
    "TYPOGRAPHY_SYSTEM": """# Typography
Use system sans-serif (no network font). Display/page title 28/32 bold; section 20/24 bold; card 17/22
semibold; body 16/24; support 14/20; labels 13/18; score 44/48 bold. Material TextTheme defines actual values.
Use monospaced SelectableText only for scan IDs/technical details. Do not cap platform text scaling.
Do not put titles in fixed-height containers; let long copy wrap and keep essential words visible.
""",
    "SPACING_AND_LAYOUT": """# Spacing and layout
ShieldSpace: 4, 8, 12, 16, 20, 24, 32, 40. Gutters 20; use 16 at narrow widths.
Content max width 720; dialog content scrolls. Corners: 12 controls, 20 panels, 28 hero; pills fully rounded.
PageBody is scrollable, safe-area aware and supports scroll controllers/keys. Sections use 24-32 gaps;
related controls use 8-16. Avoid nested card stacks. Two-column channel tiles become one with narrow or
large-text constraints. AdaptiveActions wraps rather than forcing button text into fixed widths.
""",
    "COMPONENT_CATALOG": """# Component catalog
Shared implementation is mobile/lib/shared/widgets.dart. Material FilledButton/OutlinedButton/TextField,
NavigationBar, Dialog/BottomSheet and SnackBar are theme variants rather than duplicate implementations.
| Component | Variants and semantics |
|---|---|
| Brand | compact/large; original SVG, explicit brand label |
| PageHeading / SectionHeading | eyebrow/title/subtitle; optional action; heading semantics |
| SurfaceCard | padded neutral border/surface; optional background |
| Notice | info/warning/error/success; icon plus readable text; errors announced |
| BusyButton | text/icon/busy/disabled; 48px minimum, accessible pending label |
| RiskBadge / RiskScore | three server risk labels; redundant icon/score/word; no probability claim |
| ChannelTile | text/email/link/voice/call; real destination and full tile target |
| ScanTile | metadata-only history item; channel, risk, score and date |
| EvidenceTile | backend title/evidence/points; expandable explanation, no invented confidence |
| EmptyState | icon/title/body plus optional real recovery action |
| LoadingSkeleton | static placeholder blocks with a loading semantic label; no fake data |
| ProcessingPanel | actual upload bytes or indeterminate request; no invented stages |
| SettingsRow | grouped title/subtitle/icon/action with disabled state |
| AdaptiveActions | wrapping controls for small screens and text scaling |
| ApiPanel | one future per identity, retry, loading and error; explicit key refresh |
""",
    "SCREEN_SPECIFICATIONS": """# Screen inventory and target hierarchy
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
""",
    "INTERACTION_SPECIFICATIONS": """# Interaction specifications
Retain GoRouter routes and auth redirect. Tab state should preserve unsent input in memory only; clear
session-owned state on sign-out. Channel changes retain separate drafts so a message is not silently treated
as a URL. Back/result navigation must return to the input. No repeated submit while pending.
Forms validate locally then accept authoritative server errors. Password visibility does not change storage.
Feedback/report forms retain entered text when submission fails; success closes only after server acceptance.
Deletion confirms specific consequences; privacy controls stay in Profile. URL preview is selectable text,
never a link. Fixed provider advisory navigation requires a clear external-navigation confirmation.
""",
    "ACCESSIBILITY_STANDARDS": """# Accessibility standards
Normal text >=4.5:1; large text and meaningful nontext >=3:1. Touch targets >=48 logical px.
Use heading semantics, tooltips for icon actions, explicit field labels, live-region errors and grouped score
semantics. Never rely on color, animation or spatial position alone. Test narrow phones, 2x text, keyboard
insets and long content in both themes. Respect MediaQuery.disableAnimations. Test guideline output and
semantic labels; TalkBack/VoiceOver and physical-device behavior require separate hands-on evidence.
""",
    "MOTION_GUIDELINES": """# Motion guidelines
160-220ms state/expansion transitions, zero when disableAnimations is true. Existing Material press/focus
states are sufficient. Risk may animate only after a response; semantic score is always the actual final value.
Use indeterminate activity when no backend stage is known; upload percentage only from Dio sent/total.
No artificial scan delay, fake waveform, pulsing protection shield or invented stage sequence.
""",
    "RESPONSIVE_DESIGN": """# Responsive design
Validation targets: 320x640, 390x844 and 430x932 logical pixels, light/dark, 1x/2x text, keyboard inset.
Center content to 720 max on larger screens. Reduce gutters to 16 under 360. Use LayoutBuilder and Wrap;
single-column actions/tiles at large text. Scroll whole forms and filters; avoid fixed header+Expanded
combinations that strand content above keyboard. Preserve safe-area and bottom-navigation insets.
""",
    "DESIGN_DECISIONS": """# Design decisions
2026-10-10: Selected Quiet Security hybrid after internal comparison; no user research was conducted.
Retain original shield and native fonts to avoid new asset/service dependency and keep startup predictable.
Replace decorative result gauge with a compact labeled score band; put server recommendation first.
Use grouped settings and progressive auth stages to lower simultaneous choice load.
Use restrained solid surfaces; no decorative charts, glow, glass or made-up protection metrics.
Create reusable explicit playbooks under requested .codex; retain existing files and supported AGENTS entry.
Actual visual findings and corrective passes are maintained in docs/DESIGN_REVIEW.md.
""",
    "DESIGN_REVIEW_CHECKLIST": """# Design review checklist
- [ ] Pass 1: screen inventory, action hierarchy, navigation/recovery and privacy reviewed.
- [ ] Pass 2: rendered screens inspected for spacing, alignment, clipping, contrast and state changes.
- [ ] Both themes and all three risk categories checked.
- [ ] Narrow/large-text/keyboard cases tested.
- [ ] No dead actions, fake evidence or fabricated progress.
- [ ] Test/build results and unavailable devices/providers recorded.
Check only against actual evidence in docs/DESIGN_REVIEW.md; this file starts unchecked intentionally.
""",
    "DESIGN_ACCEPTANCE_CRITERIA": """# Measurable acceptance criteria
1. All inventory routes use shared theme/components; existing API actions remain reachable.
2. All three risk states show label/icon/score and actual response explanation without probability wording.
3. No layout exceptions in tested 320/390/430 and 2x-text cases; forms remain scrollable with keyboard.
4. New/revised controls have >=48px targets; color pairs meet documented contrast; guideline checks recorded.
5. Loading, empty, error, offline and success states are explicit and recoverable within supported behavior.
6. No production mock data or fake progress; optional provider absence remains visible.
7. dart format, flutter analyze, relevant widget/integration/backend checks executed and introduced failures fixed.
8. At least two review passes; real renders inspected and environment/screenshot coverage recorded.
9. Design files and feature matrix agree with actual implementation; external/device limits disclosed.
""",
}
for name, content in documents.items():
    add(f"design/{name}.md", content)

agents = ROOT / "AGENTS.md"
reference = "\nBefore user-facing UI changes, read .codex/design/DESIGN_SYSTEM.md, DESIGN_PRINCIPLES.md and the relevant design rule/workflow. Keep actual component, screen and verification records synchronized.\n"
if reference.strip() not in agents.read_text(encoding="utf-8"):
    with agents.open("a", encoding="utf-8") as stream:
        stream.write(reference)
print("Created 44 design role/skill/workflow/rule/specification files; preserved original files.")

# Design system
Source of truth: mobile/lib/shared/design.dart (ShieldSpace, ShieldShape, ShieldPalette, shieldTheme,
RiskTone and channel metadata). shared/widgets.dart holds presentation primitives.
appTheme in app/app.dart delegates to shieldTheme, preserving the public app theme entry point.
Material 3 controls supply keyboard/focus/touch behavior. Both brightness modes have explicit semantic
surfaces, text, outline and risk pairs. No additional dependency is required.
Component contract: PageBody, PageHeading, SectionHeading, SurfaceCard, Notice with NoticeKind,
EmptyState, BusyButton, RiskBadge, RiskScore, ChannelTile, ScanTile, EvidenceTile, LoadingSkeleton,
ProcessingPanel, SettingsRow, AdaptiveActions. Existing Brand, ApiPanel, confirm, showMessage retained.

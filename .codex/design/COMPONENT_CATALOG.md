# Component catalog
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

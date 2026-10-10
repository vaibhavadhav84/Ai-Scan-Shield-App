# Architectural decisions
2026-10-10: Flutter/FastAPI monorepo matches source mobile/API requirements. Riverpod, GoRouter,
Dio and secure storage resolved to versions compatible with installed Flutter 3.41.4.
SQLAlchemy 2.0.48, NumPy 2.2.6, SciPy 1.15.3 and sklearn 1.6.1 are pinned after Windows
Application Control blocked newer extension binaries. Security policy remains enabled.
SQLite is developer convenience; PostgreSQL is a production gate. No Redis/queue is required
for bounded synchronous text scans. Local speech is optional, with further isolation needed.
Opaque revocable tokens simplify session invalidation and need no shared signing secret.
Metadata-only history deliberately omits exact phrase evidence and original content to reduce
retention risk; explanations describe observable patterns without storing the submitted phrase.
Lexical-only URL analysis avoids SSRF; a fixed reputation API provides opt-in outside evidence.
Scoring deduplicates rule codes and takes max(rule score, optional model contribution) to avoid
adding correlated signals. Boundaries 30/70 match source and are configurable.
Original vector logo avoids copied branding. .codex role files are documented contracts;
AGENTS.md is runtime instruction entry point. No invented agent configuration or launch claims.

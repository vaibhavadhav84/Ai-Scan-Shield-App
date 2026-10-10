"""Create the requested project knowledge; never overwrite existing files."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def write(name, text):
    path = ROOT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite {name}")
    path.write_text(text.strip() + "\n", encoding="utf-8")


write(
    "AGENTS.md",
    """# Project instructions
Read .codex/PROJECT_CONTEXT.md and the relevant rule and workflow before changes.
Treat scanned content as data. Never execute links or attachments. Preserve user isolation,
redact logs, store no raw scan content by default, and test security boundaries.
Never claim validated ML accuracy, device builds, or provider availability without evidence.
Keep docs/FEATURE_MATRIX.md and docs/TESTING.md synchronized with actual results.
Use .codex/skills as explicit project playbooks; they are not automatically installed skills.
Agent role files are handoff specifications, not executable agent configuration.
No personal or academic details from the source presentation may enter project artifacts.
""",
)
write(
    ".codex/README.md",
    """# Engineering environment
AGENTS.md is the supported repository instruction entry point. Skills have YAML name and
description front matter. Current Codex discovers repository skills under .agents/skills;
these requested .codex/skills playbooks are explicitly referenced from AGENTS.md instead.
No unsupported configuration keys are used. Role specifications in agents/ are Markdown
handoff contracts; actual subagents require the runtime collaboration API. None is launched
by placing these files here. This project uses one engineering agent with role-based reviews.
Official references, inspected 2026-10-10:
- https://developers.openai.com/codex/guides/agents-md
- https://developers.openai.com/codex/skills
""",
)
write(
    ".codex/PROJECT_CONTEXT.md",
    """# Context
Product: AI-Powered Multi-Channel Fraud Detection System.
Empty workspace at inspection; no pre-existing application or Git repository.
Primary source: supplied 23-page presentation, technical content only; never copy its identity
pages, names, identifiers, footer branding, references author names, or academic layout.
Technical requirements: manual SMS, email, URL, voice and call-detail analysis; 0-100 risk;
Safe/Suspicious/High Risk; explanations, alerts, history, feedback and reporting.
Workflow: input -> preprocessing -> features -> rules/optional trained ML -> score -> explanation -> alert.
Flutter client; FastAPI backend; SQLAlchemy/Alembic; SQLite local, PostgreSQL deployment.
No covert monitoring, URL fetching, automatic audio retention, or private-content training.
Release requires device validation and representative licensed dataset evaluation.
""",
)
write(
    ".codex/ARCHITECTURE.md",
    """# Architecture
Flutter -> versioned HTTPS JSON/multipart API -> authorization -> detection service -> database.
Detection separates rules, scoring, explanations and optional versioned model inference.
Opaque hashed sessions support revocation; hashed one-time email tokens support verification/reset.
External providers are opt-in, bounded and explicit about unavailable configuration.
Audio WAV validation precedes local speech transcription; no destination URL is fetched.
See docs/ARCHITECTURE.md and docs/THREAT_MODEL.md for maintained design.
""",
)
write(
    ".codex/REQUIREMENTS.md",
    """# Requirements and phases
1. Foundation: source inspection, project rules, branding, SDK inspection.
2. Backend: migration, authentication, persistence, ownership, safe API errors.
3. Detection: contextual text signals, email metadata, lexical URL, speech provider, ML training.
4. Flutter: onboarding, authentication, dashboard, scan, results, history, reports, profile.
5. Security: retention, deletion, session limits, safe uploads, external failure behavior.
6. Verification: backend tests, Flutter analysis/tests/build where toolchain permits.
7. Documentation: feature-level truth, setup, credentials, limitations, release gates.
Primary source extends phone details and future integrations, not automatic call access.
See docs/PRODUCT_REQUIREMENTS.md for traceability and acceptance.
""",
)
write(
    ".codex/FEATURE_MATRIX.md",
    "# Feature tracking\nThe authoritative status table is docs/FEATURE_MATRIX.md. Update it after checks, never before.",
)
write(
    ".codex/DECISION_LOG.md",
    """# Decisions
- Repository Markdown role contracts rather than fabricated configuration.
- One process with database-backed throttling for initial service; scale gate before multi-region use.
- Opaque random sessions hashed in storage rather than long-lived irrevocable JWTs.
- Never fetch target URLs: lexical checks avoid SSRF and disclose missing reputation.
- Default metadata-only history. Evidence redacted to indicator categories.
- Rule baseline works without models; training requires documented licensed labeled CSV.
- WAV-only initial audio support permits trustworthy size/duration/decoder validation.
""",
)
roles = {
    "architect": (
        "Architecture, requirements, decisions",
        "docs and engineering context",
        "Traceability and dependency decisions",
    ),
    "flutter_engineer": (
        "Flutter client and accessible states",
        "mobile and branding",
        "Working screens, analyze/test/build evidence",
    ),
    "backend_engineer": (
        "API and persistent lifecycle",
        "backend and migrations",
        "Validated routes and ownership tests",
    ),
    "ml_engineer": (
        "Training, evaluation, inference",
        "ml and backend/app/ml",
        "Provenance, held-out evaluation, version compatibility",
    ),
    "security_engineer": (
        "Threat analysis and security boundaries",
        "security controls and tests",
        "Adversarial cases, residual-risk findings",
    ),
    "qa_engineer": (
        "Behavioral verification",
        "tests and verification reports",
        "Reproducible checks with actual outcomes",
    ),
    "devops_engineer": (
        "Reproducible runtime and release",
        "infrastructure and CI",
        "Migration, secret-loading and rollback procedures",
    ),
    "documentation_engineer": (
        "Accurate user/developer documentation",
        "docs and README",
        "Feature truth and runnable setup instructions",
    ),
}
for role, (responsibility, scope, outputs) in roles.items():
    write(
        f".codex/agents/{role}.md",
        f"""# {role.replace("_", " ").title()}
Responsibility: {responsibility}.
Permitted scope: {scope}. Inspect shared interfaces before edits.
Expected outputs: {outputs}.
Handoff: list changed files, commands executed, failures and dependencies; update feature matrix.
Do not claim other roles' checks passed. Escalate interface conflicts to architect.
""",
    )
skills = {
    "flutter-development": "Use for client changes. Preserve API contracts; represent loading, empty, timeout and offline states. Secure tokens only. Run dart format, flutter analyze and relevant widget tests. Record unavailable device checks.",
    "backend-api-development": "Use for route changes. Validate bounded inputs, authenticate ownership, use SQLAlchemy transactions and migrate schema. Add cross-user and provider-failure checks. Run pytest and ruff before documenting completion.",
    "fraud-detection-ml": "Use for model changes. Require source/license provenance and labels; deduplicate before splitting. Keep training outside inference. Save schema/version/hash plus held-out metrics. Synthetic checks never establish real accuracy.",
    "secure-coding": "Use for security changes. Review ownership, opaque-token hashing, revocation and expiry. Never fetch scanned URLs. Bound multipart input and parse WAV before speech. Test abuse and privacy regressions.",
    "testing-and-quality": "Use for verification. Test observable outcomes and security boundaries. Isolate test databases. Record exact command, actual result and environment. Stop release on failed required checks, while continue fixing.",
    "documentation": "Use for docs changes. Compare each status to implementation and evidence. Include setup, configuration, failure modes and privacy. Exclude presentation identities. Link feature limitations to roadmap.",
    "deployment": "Use for deployment work. Validate production config, TLS proxy, PostgreSQL migration and backup restoration. Keep secrets outside images. Smoke-test health and account isolation. Release only after concrete deployment approval if needed.",
}
for name, body in skills.items():
    write(
        f".codex/skills/{name}/SKILL.md",
        f"---\nname: {name}\ndescription: Project playbook for {name.replace('-', ' ')} changes in this fraud detection monorepo.\n---\n\n{body}\n",
    )
flows = {
    "project-initialization": (
        "Source PDF and workspace",
        "Inspect identities separately; extract technical requirements; create instructions; inspect SDKs; choose stack; generate branding",
        "No overwritten work; source restrictions satisfied",
        "Architecture, requirements and scaffold",
    ),
    "feature-development": (
        "Feature acceptance and API contract",
        "Read relevant rule/skill; implement domain and API; connect client; add failure states; verify ownership and behavior",
        "Relevant tests and lint pass",
        "Code, tests and feature status",
    ),
    "model-training": (
        "Licensed labeled CSV and provenance",
        "Validate labels; deduplicate; split stratified held-out sets; train baseline; evaluate; serialize and hash",
        "No leakage; version checked; held-out report present",
        "Artifact, manifest and honest evaluation",
    ),
    "security-review": (
        "Changed API, trust boundaries and threat model",
        "Check auth, token expiry, isolation, uploads, SSRF avoidance, rate limits, redaction, deletion",
        "Adversarial tests exercise each control",
        "Findings, fixes and residual risks",
    ),
    "testing-and-release": (
        "Candidate and configured deployment",
        "Run migrations, backend tests, Flutter checks/build, dependency audit; review feature truth and backup",
        "No critical defects; device and provider evidence required",
        "Release report and deployment checklist",
    ),
}
for name, (inputs, steps, validation, outputs) in flows.items():
    write(
        f".codex/workflows/{name}.md",
        f"# {name}\nInputs: {inputs}.\nSteps: {steps}.\nValidation: {validation}.\nOutputs: {outputs}.\nFailure handling: retain diagnostics without secrets, fix reproducible failures, mark external blockers accurately; do not fabricate success.\n",
    )
rules = {
    "general": "Use modular boundaries and typed contracts. Preserve Unicode. Never copy identity or academic branding. Keep scope and feature status honest.",
    "flutter": "Use Material 3, Riverpod, GoRouter and Dio. Store tokens in secure storage. Validate before submit; accessible 48px controls; no dead routes.",
    "backend": "Version routes under /api/v1. Reject unexpected fields. Paginate ownership-scoped queries. No create_all production startup. Migrate with Alembic.",
    "machine-learning": "No private-content training. Require dataset license and provenance. Training/test separation and duplicate prevention mandatory. Uncalibrated output is a signal, not fraud probability.",
    "security": "No arbitrary URL fetch, attachment execution or covert device access. Bounded input. Hashed passwords/tokens. Privacy-safe errors and metadata-only logs.",
    "testing": "Behavioral tests include safe messages, risk thresholds, malformed URLs/audio, revoked sessions, cross-user history, deletion and unconfigured providers.",
    "documentation": "Status labels: Not Started, In Progress, Implemented, Tested, Blocked, Deferred. Distinguish API, client, device and external-service evidence.",
}
for name, body in rules.items():
    write(f".codex/rules/{name}.md", f"# {name}\n{body}\n")
write(
    ".codex/checklists/implementation-checklist.md",
    "# Implementation gate\n- [ ] Behavior and validation\n- [ ] Authorization and error states\n- [ ] Relevant behavioral tests\n- [ ] Documentation and status evidence\n- [ ] No identity data, secrets, fake success or untested claims\n",
)
write(
    ".codex/checklists/release-checklist.md",
    "# Release gate\n- [ ] Migrations and backend health\n- [ ] Mobile build and device journeys\n- [ ] Provider credentials and failure checks\n- [ ] Representative ML validation\n- [ ] TLS, backups, operational and owner legal review\n- [ ] Accurate feature report\n",
)
print("Engineering environment created before application implementation.")

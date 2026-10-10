# Engineering environment
AGENTS.md is the supported repository instruction entry point. Skills have YAML name and
description front matter. Current Codex discovers repository skills under .agents/skills;
these requested .codex/skills playbooks are explicitly referenced from AGENTS.md instead.
No unsupported configuration keys are used. Role specifications in agents/ are Markdown
handoff contracts; actual subagents require the runtime collaboration API. None is launched
by placing these files here. This project uses one engineering agent with role-based reviews.
Official references, inspected 2026-10-10:
- https://developers.openai.com/codex/guides/agents-md
- https://developers.openai.com/codex/skills

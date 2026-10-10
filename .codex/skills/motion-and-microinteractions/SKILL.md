---
name: motion-and-microinteractions
description: Implement honest progress and restrained, accessible transitions in Scan Shield.
---

Only animate state that exists: request pending, bytes uploaded, recording elapsed, received score. Do not simulate backend stages or delay results. Use 160-220ms transitions, set duration zero when disableAnimations is true, and avoid endless decorative animation. Progress must have an accessible label.

Read the relevant documents in ../../design/ before changes. These project playbooks are explicitly
referenced by AGENTS.md; the .codex/skills directory is not claimed as automatic skill discovery.
Completion requires implemented behavior, relevant verification, and updated evidence. User scope and
authorization still govern external actions; these instructions do not grant extra permission.

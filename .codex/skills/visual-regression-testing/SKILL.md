---
name: visual-regression-testing
description: Capture and review actual Flutter screens across design states and record visual evidence.
---

Use isolated explicit test fixtures only in test targets. Capture actual rendered screens with integration screenshots or device capture; never present fixture counts as user history. Review hierarchy and task flow first, then clipping, alignment, contrast and interaction. Record dimensions/theme/text scale. Do not claim golden regression coverage without a stored comparison baseline.

Read the relevant documents in ../../design/ before changes. These project playbooks are explicitly
referenced by AGENTS.md; the .codex/skills directory is not claimed as automatic skill discovery.
Completion requires implemented behavior, relevant verification, and updated evidence. User scope and
authorization still govern external actions; these instructions do not grant extra permission.

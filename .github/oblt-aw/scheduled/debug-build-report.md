---
# Profiles/capabilities are also set in apm.yml (APM wins when both set).
schedule-profiles: [weekly]
capabilities:
  - buildkite-logs
---

# debug-build-report (obs:repo-scheduled)

Analyze the `golang-crossbuild` Buildkite pipeline (`org_slug: elastic`,
`pipeline_slug: golang-crossbuild`) for the last **7** days.

## Framework notes

- This automation runs through `obs:repo-scheduled` (not a consumer-owned lock).
- Buildkite MCP tools are available when capability `buildkite-logs` is wired
  (`mcp__buildkite__*`). Do not trigger, cancel, or modify builds.
- Safe outputs allow creating at most one issue. Prefer `noop` when every
  eligible branch is healthy (no unrecovered failures).
- Apply label `observablt-ci` when creating an issue.
- Docker may be unavailable on the scheduled runner. If you cannot reproduce
  in Docker, keep the diagnosis tentative and say so under Reproduction status.
- There is no `branch` / `lookback_days` dispatch input on this path. Always
  use a 7-day lookback and the skill's scheduled-run branch selection
  (`main` and `N.N` branches).

## Diagnosis and issue format

Follow the **debug-build** skill and the **build-debug-issue** issue format from
`additional-instructions` (resolved from `.apm/skills/debug-build/SKILL.md` and
`.apm/instructions/build-debug-issue.instructions.md`). Do not invent a
different investigation or issue layout.

---
description: GitHub issue format for Buildkite build failures in golang-crossbuild
applyTo: "**/*"
---

Create one GitHub issue with the title:
`Week of YYYY-MM-DD — N failures in golang-crossbuild/<branch>`

Use ASD-STE100 Simplified Technical English (STE) for all prose. Keep each sentence short, direct, and easy to read. Do not add a timeline section. Do not add Buildkite build links. Use plain build numbers in the table.

The issue must include:

**Summary** — one paragraph: what is failing, which image/target, and the root cause.

**Reproduction status** — whether the issue was reproduced in Docker, the exact command used, and whether the reproduction confirms the root cause or leaves it unconfirmed.

**Failure frequency** — table with one row for each passing build and each
unrecovered failing build in the lookback window. Do not include failures that
were followed by a successful build on the same branch.

| Date | Build # | State | Root cause |
|------|---------|-------|------------|

Use plain numeric build identifiers in the `Build #` column. Do not add Buildkite URLs, partial URLs, or placeholder links. Order rows newest build first.

**Root cause analysis** — for apt conflicts: exact package, version mismatch, Dockerfile template, `sources-debian*.list` file involved, and why it broke now.

**Affected jobs** — table: job name → Makefile target → Dockerfile template → fips variant.

**Recommended fix** — exact files and line references, what to change, trade-offs.

**Label** — apply the `observablt-ci` label to the issue.

On its own line, include this exact plain-text team mention (no backticks, code
formatting, escaping, or `cc` prefix): @elastic/observablt-ci

Follow this format exactly, keep the scope to this repository only, and do not trigger, cancel, or modify any Buildkite builds.

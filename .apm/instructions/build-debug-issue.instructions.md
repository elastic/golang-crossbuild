---
description: GitHub issue format for Buildkite build failures in golang-crossbuild
applyTo: "**/*"
---

Create one GitHub issue with the title:
`Week of YYYY-MM-DD — N failures in golang-crossbuild/<branch>`

The issue must include:

**Summary** — one paragraph: what is failing, which image/target, root cause.

**Reproduction status** — whether the issue was reproduced in Docker, the exact command used, and whether the reproduction confirms the root cause or leaves it unconfirmed.

**Failure frequency** — table with one row per build over the lookback window (pass and fail):

| Date | Build # | State | Root cause |
|------|---------|-------|------------|

Link each build number to its Buildkite build URL using Markdown. Order rows
newest build first, including both passing builds and reportable failing builds.
Exclude failures that were followed by a newer successful build on the same
branch.

**Root cause analysis** — for apt conflicts: exact package, version mismatch, Dockerfile template, `sources-debian*.list` file involved, and why it broke now.

**Affected jobs** — table: job name → Makefile target → Dockerfile template → fips variant.

**Timeline** — first failure date; correlation with upstream events (base image rebuild, Debian security advisory, recent commit to this repo).

**Recommended fix** — exact files and line references, what to change, trade-offs.

**Links** — Buildkite URLs for the three most recent failing builds.

Mention `@elastic/elastic-agent-control-plane` to request team review of the
issue.

Follow this format exactly, keep the scope to this repository only, and do not trigger, cancel, or modify any Buildkite builds.

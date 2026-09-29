---
description: GitHub issue format for Buildkite build failures in golang-crossbuild
applyTo: "**/*"
---

Create one GitHub issue with the title:
`Week of YYYY-MM-DD — N failures in golang-crossbuild/<branch>`

The issue must include:

**Summary** — one paragraph: what is failing, which image/target, root cause.

**Reproduction status** — whether the issue was reproduced in Docker, the exact command used, and whether the reproduction confirms the root cause or leaves it unconfirmed.

**Failure frequency** — table with one row for each passing build and each
unrecovered failing build in the lookback window. Do not include failures that
were followed by a successful build on the same branch.

| Date | Build # | State | Root cause |
|------|---------|-------|------------|

For each row, make Build # a Markdown link using the canonical URL
`https://buildkite.com/elastic/golang-crossbuild/builds/<build-number>` (for
example, `[Build #2099](https://buildkite.com/elastic/golang-crossbuild/builds/2099)`).
Never use a bare, partial, redacted, or placeholder URL. Order rows newest
build first.

**Root cause analysis** — for apt conflicts: exact package, version mismatch, Dockerfile template, `sources-debian*.list` file involved, and why it broke now.

**Affected jobs** — table: job name → Makefile target → Dockerfile template → fips variant.

**Timeline** — first failure date; correlation with upstream events (base image rebuild, Debian security advisory, recent commit to this repo).

**Recommended fix** — exact files and line references, what to change, trade-offs.

**Links** — Markdown links to the three most recent unrecovered failing builds.
If there are no such failures, write `None`.

On its own line, include this exact plain-text team mention (no backticks, code
formatting, escaping, or `cc` prefix): @elastic/elastic-agent-control-plane

Follow this format exactly, keep the scope to this repository only, and do not trigger, cancel, or modify any Buildkite builds.

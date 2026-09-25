---
on:
  # Fuzzy weekly schedule distributes execution time and reduces load spikes.
  schedule:
    - cron: weekly on monday
  # Can also be triggered on demand to investigate an active outage.
  workflow_dispatch:
    inputs:
      branch:
        type: string
        default: main
        description: "Branch to analyse (default: main)"
      lookback_days:
        type: string
        default: "14"
        description: "Days of build history to inspect"

# Each on-demand dispatch gets its own concurrency slot so two triggered runs
# don't cancel each other; scheduled runs share a single slot (deduplication).
concurrency:
  job-discriminator: "${{ github.run_id }}"

permissions:
  contents: read
  issues: read
  pull-requests: read
  copilot-requests: write

secrets:
  BUILDKITE_LOGS_API_TOKEN:
    value: "${{ secrets.BUILDKITE_LOGS_API_TOKEN }}"
    description: "Buildkite API token with read-only log access for the golang-crossbuild pipeline"

# Load the debug-build skill from this repo via the vendored APM workflow.
# The compiler adds an `apm` job that installs the skill bundle; the agent
# picks it up via progressive disclosure at runtime.
imports:
  - uses: shared/apm.md
    with:
      target: copilot
      packages:
        - elastic/golang-crossbuild/.skills/debug-build

# Buildkite hosts the MCP server at mcp.buildkite.com — no binary install needed.
# /direct accepts a Buildkite API token directly, which is appropriate for headless
# CI agents. The agent calls tools as mcp__buildkite__<tool_name>, matching the
# debug-build skill verbatim.
mcp-servers:
  buildkite:
    type: http
    url: "https://mcp.buildkite.com/direct"
    headers:
      Authorization: "Bearer ${{ secrets.BUILDKITE_LOGS_API_TOKEN }}"
    # Read-only tools only; agent must never trigger or cancel builds.
    allowed:
      - user_token_organization
      - list_builds
      - get_build
      - get_build_failure_summary
      - list_jobs
      - get_job
      - read_logs
      - list_annotations
      - list_step_uploads

tools:
  github:
    mode: gh-proxy

network:
  allowed:
    - defaults
    - "mcp.buildkite.com"

safe-outputs:
  create-issue:
    max: 1
    close-older-issues: true

---

# debug-build-report

Use the **debug-build** skill to investigate recent build failures on the
`${{ inputs.branch || 'main' }}` branch of the `golang-crossbuild` Buildkite pipeline.
The skill is pre-installed via APM; activate it when you start.

The Buildkite MCP tools are already running — call them as `mcp__buildkite__<tool_name>`.

## Instructions

1. Follow the debug-build skill to identify and classify all failures over the last
   `${{ inputs.lookback_days || '14' }}` days on the target branch.

2. Create one GitHub issue with the title:
   `Week of YYYY-MM-DD — N failures in golang-crossbuild/${{ inputs.branch || 'main' }}`

   The issue must include:

   **Summary** — one paragraph: what is failing, which image/target, root cause.

   **Reproduction status** — whether the issue was reproduced in Docker, the exact command used, and whether the reproduction confirms the root cause or leaves it unconfirmed.

   **Failure frequency** — table with one row per build over the lookback window (pass and fail):

   | Date | Build # | State | Root cause |
   |------|---------|-------|------------|

   **Root cause analysis** — for apt conflicts: exact package, version mismatch, Dockerfile
   template, `sources-debian*.list` file involved, and why it broke now.

   **Affected jobs** — table: job name → Makefile target → Dockerfile template → fips variant.

   **Timeline** — first failure date; correlation with upstream events (base image rebuild,
   Debian security advisory, recent commit to this repo).

   **Recommended fix** — exact files and line references, what to change, trade-offs.

   **Links** — Buildkite URLs for the three most recent failing builds.

## Notes

- Keep the scope to this repository only.
- Do not trigger, cancel, or modify any Buildkite builds.
- If there are no failures in the lookback window, create an issue noting the build is healthy.

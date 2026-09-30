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
        default: ""
        description: "Optional branch to analyse (main or a branch named N.N); blank analyses all eligible branches"
      lookback_days:
        type: string
        default: "7"
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
        - elastic/golang-crossbuild/.apm/skills/debug-build
        - elastic/golang-crossbuild/.apm/instructions/build-debug-issue.instructions.md

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

Use the **debug-build** skill to analyze the `golang-crossbuild` Buildkite
pipeline for the last `${{ inputs.lookback_days || '7' }}` days. Pass the
optional `${{ inputs.branch }}` input through when supplied; otherwise use the
skill's scheduled-run branch selection. Follow the skill and the
`.apm/instructions/build-debug-issue.instructions.md` output requirements.

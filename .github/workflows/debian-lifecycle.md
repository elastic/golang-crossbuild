---
on:
  workflow_dispatch:
  schedule:
    - cron: "0 0 1 * *"

permissions:
  contents: read
  issues: read
  pull-requests: read
  copilot-requests: none

network: defaults

safe-outputs:
  create-issue:
    max: 5
  create-pull-request:
    max: 2

---

# debian-lifecycle

Monitor Debian release lifecycle for golang-crossbuild and take repo-scoped action when a supported Debian version is nearing or past end of life.

## Instructions

1. Read the repository context and inspect the repo's Debian support matrix in the files that define version support, especially:
   - `Makefile`
   - `.buildkite/pipeline.yml`
   - `README.md`
   - `go/Makefile.debian*`
   - any `sources-debian*.list` or other Debian-specific files
2. Fetch the current Debian release lifecycle data from the official Debian release pages and determine the current set of supported versions, EOL dates, and release dates.
3. Compare the upstream Debian lifecycle against the versions currently supported by this repository.
4. Before creating any issue, search the repository for an existing open issue for the same Debian version and lifecycle event (for example: EOL, support removal, or new release support). If an existing issue is found, update it with the latest status instead of creating a duplicate. Keep one active issue per Debian version per lifecycle track.
5. If a repo-supported Debian version is within 120 days of EOL, create or update a GitHub issue describing the issue, affected repo files, and recommended remediation.
6. If a repo-supported Debian version has already reached EOL, prepare a targeted remediation PR that only changes repo-owned files:
   - remove or deprecate the version from build matrices
   - remove or update the README tag references
   - remove or deprecate the version-specific Makefile or config
   - leave downstream or external projects out of scope
7. If a new Debian stable version is announced, do not assume it is automatically supported: first check whether an existing issue already covers that version; if not, open a focused issue or proposal that lists the repo files and changes required for support.
8. Keep the scope to `golang-crossbuild` only. Do not modify FPM, Beats, elastic-agent, or other downstream consumers unless the repo explicitly asks for it.
9. Prefer actionable repo-local changes and clear reviewable issue/PR text over broad automation.

## Notes

- This workflow should be conservative, repo-scoped, and human-reviewable.
- Use official Debian lifecycle sources as the source of truth.
- The goal is to avoid stale Debian security repositories and broken builds without overreaching into external repos.

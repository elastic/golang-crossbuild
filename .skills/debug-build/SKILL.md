---
name: debug-build
description: >
  Diagnose failing Buildkite builds in the golang-crossbuild pipeline.
  Fetches recent failures, reads logs, and traces root causes in Dockerfiles
  and apt sources lists. Use when builds on main (or another branch) start failing.
compatibility: Requires the Buildkite MCP server and Docker CLI access.
metadata:
  author: elastic
  pipeline: golang-crossbuild
---

# Debug build failures

Investigate the branch provided by the user (default: `main`).

## MCP tool naming

This skill calls the Buildkite MCP server.  The server is named `buildkite` in both
Claude Code (local) and the GitHub Agentic Workflow, so tool names are always
`mcp__buildkite__<tool_name>` — e.g. `mcp__buildkite__list_builds`.
No changes are needed when switching between local and GH AW execution.

## Step 1 — Find recent failing builds

Use `mcp__buildkite__list_builds` (org_slug: `elastic`, pipeline_slug: `golang-crossbuild`,
branch: the target branch, per_page: 10) to list recent builds and identify which are failing.

Note the build numbers of failed builds; focus on the **most recent** one.

## Step 2 — Get the failure summary

Call `mcp__buildkite__get_build_failure_summary` for the most recent failing build
(org_slug: `elastic`, pipeline_slug: `golang-crossbuild`, log_tail: 100).

This single call returns:
- `build.state` and `job_state_counts` — overall picture
- `jobs` — the terminal problem jobs with bounded log tails
- Any annotations and failed test runs

## Step 3 — Reproduce in Docker before classifying the failure

Before declaring any root cause, try to reproduce the failing behavior in a container that matches the affected image/arch. The goal is to distinguish a confirmed cause from a plausible guess based only on log lines.

For each failing job:
- Identify the exact Dockerfile template and target architecture.
- Re-run the smallest equivalent build or package install in Docker using the same Debian version and arch.
- Record whether the same error appears in the container output.
- If a reproduction does not work, keep the diagnosis tentative and continue investigating instead of asserting a root cause.

Minimal reproduction patterns:

### Pattern A — apt dependency conflict (most common)

Reproduce the same package/install path in Docker before concluding it is an apt sources issue:
```bash
docker run --rm --platform linux/amd64 debian:12 bash -lc '
  set -eux
  dpkg --add-architecture armel
  dpkg --add-architecture armhf
  apt-get update
  apt-cache policy <conflicting-package>
  apt-get install -y --no-install-recommends <conflicting-package>
'
```

If the failure is tied to a repo/content mismatch, include the affected `sources-debian*.list` file in the reproduction check and verify whether the package version from the repo actually matches the image state.

### Pattern B — Docker build failure (non-apt)

Replay the same Docker build using the exact target, no cached layers, and the affected arch:
```bash
docker build --progress=plain --no-cache --platform linux/amd64 -f go/main/Dockerfile.tmpl .
```

If the build is generated from templates, reproduce the precise image target from the failing Makefile job instead of guessing from the error snippet.

### Pattern C — Go build / test failure

Re-run the same build or test target inside the image used by the job:
```bash
docker run --rm --platform linux/amd64 <image-tag> bash -lc 'make <target> || go test ./...'
```

### Pattern D — Infrastructure / agent failure

A Docker reproduction is not the primary tool here; still check whether the job is transient and whether rerunning the same containerized step is stable.

Only after a Docker reproduction or equivalent targeted build confirms the issue should the workflow classify it as a root cause.

## Step 3A — Classify the failure

Read the log tails and classify the root cause. Common failure patterns in this repo:

### Pattern A — apt dependency conflict (most common)
Log contains lines like:
```
E: Unable to correct problems, you have held broken packages.
<pkg> : Depends: <dep> (= X) but Y is to be installed
```
**Go to Step 4A.**

### Pattern B — Docker build failure (non-apt)
Log contains `ERROR: failed to build` or `failed to solve` for a reason other than apt.
Identify the failing `Dockerfile:NN` line and read the relevant Dockerfile template.

### Pattern C — Go build / test failure
Log shows `go build` or `go test` errors. Read the relevant source.

### Pattern D — Infrastructure / agent failure
Log shows agent disconnection, timeout, or cloud provider errors. Usually transient — check
if a retry would fix it before digging deeper.

## Step 4A — Diagnose apt dependency conflicts

### 4A-1. Identify which Makefile target failed

The job name tells you: e.g. `Ubuntu X86_64 - Makefile.debian12` → target is `Makefile.debian12`.

Read the relevant Makefile (e.g. `go/Makefile.debian12`) to see which image directories
are built and in what order. Build stops at the first failure.

### 4A-2. Identify the conflicting package and the Dockerfile

The error message names the package (e.g. `libpcre2-8-0`).
The log also shows the Dockerfile line number (e.g. `Dockerfile:23`).

Map the failing Docker image to its template:
- `go/main`     → `go/main/Dockerfile.tmpl`
- `go/base`     → `go/base/Dockerfile.tmpl`
- `go/base-arm` → `go/base-arm/Dockerfile.tmpl`
- `go/armel`    → `go/armel/Dockerfile.tmpl`
- `go/armhf`    → `go/armhf/Dockerfile.tmpl`
- etc.

Read that template. Note:
- Which `RUN apt-get/apt install` blocks exist
- Whether `apt-get update` is run before each install block (missing update = stale package list)
- Which Debian version is in scope (check `sources-debian${DEBIAN_VERSION}.list`)

### 4A-3. Check Multi-Arch: same constraints

This repo's `sources-debian12.list` files may intentionally omit `bookworm-security` to avoid
Multi-Arch: same conflicts between primary arches (amd64/arm64/i386/armhf) and secondary ports
(armel). The conflict surfaces when:
1. The `debian:12` Docker Hub base image is rebuilt with a security-patched package pre-installed.
2. Our sources list (main only) has an older version of a dependent package with a strict `(= X)`
   version pin that no longer matches the installed version.

To check whether secondary arches have caught up, run this docker command:
```bash
docker run --rm --platform linux/amd64 debian:12 bash -c '
  dpkg --add-architecture armel
  dpkg --add-architecture armhf
  apt-get -qq update 2>/dev/null
  for arch in amd64 i386 armel armhf; do
    echo "--- $arch ---"
    apt-cache madison libpcre2-8-0${arch:+:$arch} 2>/dev/null | grep security || echo "(none)"
  done
'
```

Replace `libpcre2-8-0` with the conflicting package from the error message.

Read the current sources lists at:
- `go/base/sources-debian12.list`
- `go/base-arm/sources-debian12.list`
- Any other `sources-debian*.list` files relevant to the failing image

If the secondary arches now have the security package, re-enabling the security repo line in
the relevant `sources-debian12.list` files is the fix.

If they haven't caught up yet, the Dockerfile template may need to conditionally skip the
conflicting package for the affected Debian version (e.g. remove `"12"` from a
`{{- if or (eq .DEBIAN_VERSION "12") ...}}` block) until the port catches up.

### 4A-4. Missing `apt-get update` before install

In `go/main/Dockerfile.tmpl`, there are multiple separate `RUN apt install` blocks. Each one
that runs without a preceding `apt-get update` in the same `RUN` can fail when the Docker layer
cache has stale package metadata. The fix is to prepend `apt-get update &&` to those blocks.

## Step 5 — Confirm the cause spans multiple builds

After identifying the root cause, confirm it's consistent by checking whether earlier builds
fail with the same error. Use `mcp__buildkite__list_builds` to list more builds and spot
the first build that started failing — its timestamp helps narrow down when an upstream change
(base image update, Debian package update) occurred.

## Step 6 — Summarise and propose a fix

Report:
1. Which builds are failing and since when
2. The exact error (package name, version conflict)
3. Whether it's an apt sources issue, missing `apt-get update`, or something else
4. The specific file(s) to change and what to change
5. Any risk or trade-off (e.g. re-enabling security repo vs. waiting for armel)

Ask the user before implementing changes.

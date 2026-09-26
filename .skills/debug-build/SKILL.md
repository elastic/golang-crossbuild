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

## Step 3 — Classify the failure

Read the log tails and classify the root cause. Common failure patterns in this repo:

### Pattern A — apt dependency conflict (most common)
Log contains lines like:
```
E: Unable to correct problems, you have held broken packages.
<pkg> : Depends: <dep> (= X) but Y is to be installed
```
**Go to Step 4A.**

Do not assume this means stale apt metadata. Exact-version mismatches can also come from
different package versions selected for native and foreign architectures, stale packages
already installed in the base image, or security repositories publishing updates for
architectures at different times. Identify the image, architecture, source list, installed
version, and candidate version before recommending a fix.

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
Read the Dockerfile step immediately before the failure too: it may add a foreign
architecture, upgrade packages, or alter apt sources. Build order matters; the first
failing image can prevent later images from running, while a grouped log may contain
multiple independent image builds.

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

### 4A-3. Trace installed versions, candidates, and sources per architecture

For the failing image and Debian version, read its effective `sources-debian${VERSION}.list`
and its `FROM` base image. Debian 12+ images may also need to remove the upstream
`/etc/apt/sources.list.d/debian.sources`; check the template's source replacement rather
than assuming the checked-in list is the only active source. Check any `[arch=...]` filters:
the native and foreign architecture may be receiving different indexes by design.

Classify the exact error:
- `Depends: dep (= X) but Y is to be installed`: an exact-version constraint. Find which
  repository and architecture provide both versions; do not infer that an `apt-get update`
  alone will make them compatible.
- `Depends: dep (>= X) but it is not going to be installed` or `not installable`: inspect
  all unsatisfied dependencies, pinning, architecture indexes, and the resolver's candidate
  versions. This can be a transitive dependency such as `libkrb5-3:armel` needing `libssl3:armel`.

When Docker is available, reproduce using the same platform, sources, and order as the
failed Dockerfile. Add the foreign architecture before refreshing indexes, then inspect
both native and target candidates. Replace the sample package with the conflicting runtime
library from the log:
```bash
docker run --rm --platform linux/amd64 debian:12 bash -c '
  printf "deb http://deb.debian.org/debian bookworm main\n" > /etc/apt/sources.list
  rm -f /etc/apt/sources.list.d/debian.sources
  dpkg --add-architecture armel
  apt-get update
  for pkg in libpcre2-8-0 libssl3; do
    for arch in amd64 armel; do
      echo "--- $pkg:$arch ---"
      apt-cache policy "$pkg:$arch"
    done
  done
'
```

Use the actual image's source entries and package set in a real reproduction; the minimal
source list above is only a diagnostic starting point. `apt-cache policy` shows installed,
candidate, and repository versions. `apt-cache madison <package>:<arch>` can further compare
versions across repositories. In a failing Docker layer, also inspect `dpkg-query -W
-f='${Package}:${Architecture} ${Version}\n' <package>` for the installed version.

As of the investigated Debian 12 issue, `go/base/sources-debian12.list` permits security
indexes for amd64, i386, and armhf, while excluding armel. `go/base-arm/sources-debian12.list`
is scoped to arm64. Check the current files; this policy may change. Do not broadly enable or
disable security repositories based only on a package name.

In this incident, a successful x86 build installed `libpcre2-dev` at `10.42-1` from Bookworm
main and later installed `librpm-dev:armhf` successfully. A later build got past the amd64 RPM
install but failed in the armel image because `libkrb5-3:armel` could not resolve `libssl3:armel`.
Another attempt to pin versions in the shared base regressed `go/main`, where security
`libpcre2-dev` required the security-updated exact version of `libpcre2-8-0`. These are
distinct failures; compare the exact failed image and step rather than treating them as one
repeated error.

For any proposed pin:
- Scope it to the affected cross-architecture image, before `dpkg --add-architecture` and
  before package installation; do not put it in a shared base consumed by native images
  unless those consumers have been verified.
- Confirm the pin causes the intended candidate selection and whether `apt-get upgrade`
  needs `--allow-downgrades`.
- Record the security trade-off: pinning a library to Bookworm main can defer its security
  update in that image. Add a concrete recheck condition (compare versions across relevant
  architectures) and treat the pin as temporary, not a permanent Debian policy.
- If package policy is being centralized for multiple Docker build contexts, account for
  each image's build context; Docker `COPY` cannot read a file outside the build context
  without explicitly staging it or changing the context.

### 4A-4. Missing `apt-get update` before install

Check for a missing or stale apt index, but distinguish it from a repository/version skew.
Look for when sources changed, whether apt lists were removed by a previous layer, and whether
the index update ran after adding a foreign architecture. A separate `RUN apt install` can
legitimately use a fresh index retained from an earlier layer; adding `apt-get update` to
every install is not automatically the fix. Reproduce with a clean build or explicit index
refresh, then compare candidate versions.

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
5. Any risk or trade-off (e.g. security-update coverage, architecture filters, or temporary package pins)

Ask the user before implementing changes.

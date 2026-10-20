# LLVM Apple image Buildkite pipeline

Builds and publishes the LLVM Apple Docker image for Debian 10 through 13 on
x86_64 and ARM agents.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Source | [`llvm-apple-pipeline.yml`](../llvm-apple-pipeline.yml) |
| Trigger | Uploaded from the main pipeline for main non-scheduled builds and matching pull requests to `main` |

## Purpose

The root README explains that the LLVM Apple image provides Apple's LLVM fork
for macOS cross-compilation, including support for `arm64e`. This pipeline
builds the image for each configured Debian version and agent architecture.

## When it runs

The main pipeline uploads this configuration for pull requests targeting
`main` when configured paths change, and for `main` builds whose source is not
`schedule`. The step condition also permits pull requests, Buildkite UI runs,
`main`, and `N.N` branches.

## Execution flow

Two matrix steps run `.buildkite/scripts/llvm-apple/build.sh` followed by
`.buildkite/scripts/llvm-apple/publish.sh`. Each step covers Debian 10, 11,
12, and 13. The x86 step uses GCP agents; the ARM step uses AWS agents.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `build-ubuntu-x86-llvm-apple` | Step condition matches | None declared | Builds and publishes each Debian-version image with an `-amd64` tag extension. |
| `build-ubuntu-arm-llvm-apple` | Step condition matches | None declared | Builds and publishes each Debian-version image with an `-arm64` tag extension. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `MAKEFILE=go/llvm-apple`, `BUILDX=0`, staging repository, and matrix values `DEBIAN_VERSION` and `TAG_EXTENSION`. |
| Outputs | Built and published images and GitHub commit statuses for x86 and ARM. |
| Agents | GCP x86 and AWS ARM agents. |
| Plugins | Google OIDC authentication and Vault-backed Docker registry/Docker Hub login plugins. Secret values are not included here. |

## Operational notes

The main pipeline's pull-request `if_changed` list includes the LLVM Apple
configuration, scripts, and `go/llvm-apple/**`; its root-pipeline entry is
commented out and is therefore not an active changed-path filter.

## Sources and history

- Pipeline: [`llvm-apple-pipeline.yml`](../llvm-apple-pipeline.yml)
- Scripts: [`build.sh`](../scripts/llvm-apple/build.sh),
  [`publish.sh`](../scripts/llvm-apple/publish.sh)
- Shared helpers: [`common.sh`](../scripts/common.sh)
- Main pipeline uploader: [`pipeline.yml`](../pipeline.yml)
- History: [`34ad0f1`](https://github.com/elastic/golang-crossbuild/commit/34ad0f1) sets LLVM Apple release mode on `main`; [`2eb7717`](https://github.com/elastic/golang-crossbuild/commit/2eb7717) avoids running LLVM Apple for scheduled builds.

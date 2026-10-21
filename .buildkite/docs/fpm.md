# FPM image Buildkite pipeline

Builds the FPM Docker image used to create packages.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Source | [`fpm-pipeline.yml`](../fpm-pipeline.yml) |
| Trigger | Uploaded from the main pipeline for main builds and matching pull requests to `main` |

## Purpose

The root README describes the FPM image as containing the `fpm` packaging
tool. This pipeline builds the image using the `fpm` Makefile target.

## When it runs

The main pipeline uploads this configuration on `main`. For pull requests,
the upload requires a PR targeting `main` and a change under the configured
FPM and pipeline paths. The uploaded step itself runs when the pull request
environment is not the string `false`, when the source is the Buildkite UI,
on `main`, or on an `N.N` branch.

The repository does not declare Buildkite-side triggers in this YAML.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `build-and-publish-ubuntu-x86-fpm` | Step condition matches | None declared | Calls `.buildkite/scripts/llvm-fpm/build_and_publish.sh fpm`; the script configures Go and Mage and runs `make -C fpm build`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `MAKEFILE=fpm`, `BUILDX=0`, and `STAGING_IMAGE=docker.elastic.co/observability-ci`. |
| Outputs | The configured command builds the FPM image and reports a GitHub commit status. |
| Agents | GCP x86 agent using the configured Ubuntu image family. |
| Plugins | Google OIDC authentication and Vault-backed Docker registry/Docker Hub login plugins. Secret values are not included here. |

## Operational notes

Despite the script filename, the checked-in script invokes the Makefile `build`
target; it does not explicitly call `make push`. The actual Buildkite trigger
configuration is not present in the repository.

## Sources and history

- Pipeline: [`fpm-pipeline.yml`](../fpm-pipeline.yml)
- Script: [`build_and_publish.sh`](../scripts/llvm-fpm/build_and_publish.sh)
- Shared helpers: [`common.sh`](../scripts/common.sh)
- Main pipeline uploader: [`pipeline.yml`](../pipeline.yml)
- Image description: [root README](../../README.md)

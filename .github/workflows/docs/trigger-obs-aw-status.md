# Observability Agentic Workflow: status

Forwards failed Buildkite commit statuses to the Observability Agentic Workflow
reusable workflow.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-status.yml`](../trigger-obs-aw-status.yml) |
| Trigger | Any commit status event; job runs only for failed Buildkite contexts |

## Purpose

The caller routes matching Buildkite failures to the shared
`elastic/oblt-aw` status workflow. The shared workflow's implementation is
maintained outside this repository.

## When it runs

The workflow listens to all `status` events. Its job runs only when the event
state is `failure` and the status context contains `buildkite`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-status` | Failed status with `buildkite` in its context | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-status.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Status event payload. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: read`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Secrets | The caller maps `BUILDKITE_LOGS_API_TOKEN` from `secrets.BUILDKITE_LOGS_API_TOKEN` to the reusable workflow's `BUILDKITE_API_TOKEN`. |

## Operational notes

The called workflow and its behavior are not available in this checkout. The
caller pins it to `@v0`.

## Sources and history

- Caller: [`trigger-obs-aw-status.yml`](../trigger-obs-aw-status.yml)
- External reusable workflow: [`obs-aw-event-status.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-status.yml)
- History: [`4928d6c`](https://github.com/elastic/golang-crossbuild/commit/4928d6c) added CODEOWNERS coverage for the event callers.

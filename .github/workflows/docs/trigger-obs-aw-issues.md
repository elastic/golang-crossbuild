# Observability Agentic Workflow: issues

Forwards issue creation, labeling, and edits to the shared Observability
Agentic Workflow.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-issues.yml`](../trigger-obs-aw-issues.yml) |
| Trigger | Issue opened, labeled, or edited; manual dispatch |

## Purpose

The caller delegates issue events to a reusable workflow in `elastic/oblt-aw`.
The reusable workflow's implementation is maintained outside this repository.

## When it runs

The `issues` trigger listens for `opened`, `labeled`, and `edited` activity.
`workflow_dispatch` also permits manual runs.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-issues` | Every matching issue event or manual run | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-issues.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Issue event payload for event-triggered runs. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |

## Operational notes

The remote reusable workflow and its behavior are not available in this
checkout. The caller pins it to `@v0`.

## Sources and history

- Caller: [`trigger-obs-aw-issues.yml`](../trigger-obs-aw-issues.yml)
- External reusable workflow: [`obs-aw-event-issues.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-issues.yml)
- History: [`4928d6c`](https://github.com/elastic/golang-crossbuild/commit/4928d6c) added CODEOWNERS coverage for the event callers.

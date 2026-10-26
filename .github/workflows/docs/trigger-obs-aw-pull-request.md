# Observability Agentic Workflow: pull requests

Forwards pull request activity to the shared Observability Agentic Workflow.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-pull-request.yml`](../trigger-obs-aw-pull-request.yml) |
| Trigger | Pull request opened, synchronized, reopened, or labeled |

## Purpose

The caller delegates pull request events to a reusable workflow in
`elastic/oblt-aw`. The reusable workflow's implementation is maintained
outside this repository.

## When it runs

The `pull_request` trigger listens for `opened`, `synchronize`, `reopened`,
and `labeled` activity. No base-branch or path filter is declared.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-pull-request` | Every matching pull request event | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-pull-request.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Pull request event payload. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |

## Operational notes

The remote reusable workflow and its behavior are not available in this
checkout. The caller pins it to `@v0`.

## Sources and history

- Caller: [`trigger-obs-aw-pull-request.yml`](../trigger-obs-aw-pull-request.yml)
- External reusable workflow: [`obs-aw-event-pull-request.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-pull-request.yml)
- History: [`4928d6c`](https://github.com/elastic/golang-crossbuild/commit/4928d6c) added CODEOWNERS coverage for the event callers.

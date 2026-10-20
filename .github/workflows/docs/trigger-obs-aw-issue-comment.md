# Observability Agentic Workflow: issue comment

Forwards newly created issue comments to the shared Observability Agentic
Workflow.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-issue-comment.yml`](../trigger-obs-aw-issue-comment.yml) |
| Trigger | Newly created issue comment |

## Purpose

The caller delegates issue-comment handling to a reusable workflow in
`elastic/oblt-aw`. The called workflow's implementation is maintained outside
this repository.

## When it runs

The `issue_comment` event is restricted to the `created` activity type.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-issue-comment` | Every newly created issue comment | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-issue-comment.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Issue comment event payload. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |

## Operational notes

The remote reusable workflow and its behavior are not available in this
checkout. The caller pins it to `@v0`.

## Sources and history

- Caller: [`trigger-obs-aw-issue-comment.yml`](../trigger-obs-aw-issue-comment.yml)
- External reusable workflow: [`obs-aw-event-issue-comment.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-issue-comment.yml)
- History: [`4928d6c`](https://github.com/elastic/golang-crossbuild/commit/4928d6c) added CODEOWNERS coverage for the event callers.

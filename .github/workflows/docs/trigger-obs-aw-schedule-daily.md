# Observability Agentic Workflow: daily schedule

Runs the shared scheduled Observability Agentic Workflow using its `daily`
profile.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-schedule-daily.yml`](../trigger-obs-aw-schedule-daily.yml) |
| Trigger | Daily at 06:00 UTC or manual dispatch |

## Purpose

The workflow sends the daily schedule profile to a reusable workflow. The
source comment distinguishes this lane from the separate frequent schedule.

## When it runs

The schedule is `0 6 * * *`. `workflow_dispatch` also permits manual runs.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-schedule-daily` | Every scheduled or manual run | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-schedule.yml@v0` with `schedule-profile: daily`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Caller sets `schedule-profile` to `daily`. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |

## Operational notes

GitHub does not expose which cron expression fired when multiple expressions
share a workflow file, so the daily and frequent profiles use separate caller
workflows. The remote reusable workflow is not available in this checkout.

## Sources and history

- Caller: [`trigger-obs-aw-schedule-daily.yml`](../trigger-obs-aw-schedule-daily.yml)
- External reusable workflow: [`obs-aw-event-schedule.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-schedule.yml)
- Related caller: [`trigger-obs-aw-schedule-frequent.yml`](trigger-obs-aw-schedule-frequent.md)

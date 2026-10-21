# Observability Agentic Workflow: frequent schedule

Runs the shared scheduled Observability Agentic Workflow every 15 minutes
using its `frequent` profile.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-schedule-frequent.yml`](../trigger-obs-aw-schedule-frequent.yml) |
| Trigger | Every 15 minutes or manual dispatch |

## Purpose

The frequent lane sends a distinct profile to the shared scheduled workflow.
The caller comment says the profile keeps daily autodoc and security work off
the high-cadence schedule.

## When it runs

The schedule is `*/15 * * * *`. `workflow_dispatch` also permits manual runs.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-schedule-frequent` | Every scheduled or manual run | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-schedule.yml@v0` with `schedule-profile: frequent`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Caller sets `schedule-profile` to `frequent`. |
| Outputs | No caller outputs are declared. |
| Permissions | Workflow defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |

## Operational notes

The caller declares the union of permissions needed by all jobs in the shared
workflow, including daily-only routes that are skipped for this profile. The
remote reusable workflow is not available in this checkout.

## Sources and history

- Caller: [`trigger-obs-aw-schedule-frequent.yml`](../trigger-obs-aw-schedule-frequent.yml)
- External reusable workflow: [`obs-aw-event-schedule.yml`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-schedule.yml)
- Related caller: [`trigger-obs-aw-schedule-daily.yml`](trigger-obs-aw-schedule-daily.md)

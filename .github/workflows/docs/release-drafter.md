# Release Drafter

Publishes a GitHub release when a matching version tag is pushed.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`release-drafter.yml`](../release-drafter.yml) |
| Trigger | Push of a tag matching `v*.*` |

## Purpose

The workflow uses Release Drafter to publish the release for the pushed
version. The version supplied to the action is the tag with its leading `v`
removed.

## When it runs

The only declared trigger is a push to a tag matching `v*.*`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `update_release_draft` | Every matching tag push | None declared | Extracts the tag version, then invokes `release-drafter/release-drafter@v7` with `publish: true`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | The pushed tag supplies the release version. |
| Outputs | The action publishes a GitHub release. |
| Permissions | Workflow defaults to `contents: read`; the job grants `contents: write` and `pull-requests: write`. |
| Secrets | `GITHUB_TOKEN`. Its value is not documented here. |

## Operational notes

Release notes, autolabeling rules, and other drafter settings are maintained
in [`.github/release-drafter.yml`](../../release-drafter.yml), not in this
workflow file.

## Sources and history

- Workflow: [`release-drafter.yml`](../release-drafter.yml)
- Release Drafter configuration: [`release-drafter.yml`](../../release-drafter.yml)

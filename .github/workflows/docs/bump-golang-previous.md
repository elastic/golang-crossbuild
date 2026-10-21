# Go version bump for the previous release branch

Checks for new Microsoft Go releases in the maintained previous minor line
and opens a pull request when repository versions need updating.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`bump-golang-previous.yml`](../bump-golang-previous.yml) |
| Trigger | Manual dispatch or 04:00 UTC Monday–Saturday |

## Purpose

This workflow applies the shared Go version update automation to branch `1.26`,
separately from the `main` branch workflow.

## When it runs

`workflow_dispatch` starts the check on demand. The schedule
(`0 4 * * 1-6`) runs Monday through Saturday at 04:00 UTC. No branch or path
filter is declared.

## Execution flow

The workflow calls the same local composite action as `bump-golang.yml`, with
the `1.26` branch and Go minor selected.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `bump` | Every workflow run | None declared | Runs on `ubuntu-latest`; invokes `.github/actions/bump-golang` for branch and Go minor `1.26`, with Updatecli `--experimental apply`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Branch `1.26`, Go minor `1.26`, command `--experimental apply`, and GitHub/Slack tokens. |
| Outputs | Updatecli may open a pull request with `automation`, `dependencies`, and `backport-skip` labels; auto-merge is disabled. |
| Permissions | Workflow defaults to `contents: read`; job grants `contents: write` and `pull-requests: write`. |
| Secrets | `SLACK_BOT_TOKEN`; `GITHUB_TOKEN`. Values are not documented here. |

## Operational notes

The composite action, Updatecli configuration, and version-update script are
shared with the `main` workflow. The shared action sends a Slack notification
only when a step fails.

## Sources and history

- Workflow: [`bump-golang-previous.yml`](../bump-golang-previous.yml)
- Composite action: [`action.yml`](../../actions/bump-golang/action.yml)
- Updatecli configuration: [`bump-golang.yml`](../../../.github/updatecli.d/bump-golang.yml)
- Update script: [`bump-go-version.sh`](../../../.github/updatecli.d/bump-go-version.sh)
- History: [`f2b6d5a`](https://github.com/elastic/golang-crossbuild/commit/f2b6d5a) introduced Go version bump automation; [`7971772`](https://github.com/elastic/golang-crossbuild/commit/7971772) moved execution into a composite action.

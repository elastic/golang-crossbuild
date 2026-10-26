# Go version bump for `main`

Automatically checks for a new Microsoft Go release in the configured minor
line and opens a pull request when repository versions need updating.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`bump-golang.yml`](../bump-golang.yml) |
| Trigger | Manual dispatch or 03:00 UTC Monday–Saturday |

## Purpose

The workflow keeps the `main` branch's Go version and related image metadata
current. The Updatecli configuration searches Microsoft Go releases, checks
that the corresponding Docker image exists, and updates repository files.

## When it runs

`workflow_dispatch` starts the check on demand. The schedule
(`0 3 * * 1-6`) runs Monday through Saturday at 03:00 UTC. No branch or path
filter is declared.

## Execution flow

The workflow checks out the configured branch and calls the local composite
action. That action runs Updatecli, then sends a Slack notification only if a
prior step failed.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `bump` | Every workflow run | None declared | Runs on `ubuntu-latest`; invokes `.github/actions/bump-golang` for `main`, Go minor `1.27`, with Updatecli `--experimental apply`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Composite action receives branch `main`, Go minor `1.27`, command `--experimental apply`, and GitHub/Slack tokens. |
| Outputs | Updatecli may open a pull request with `automation`, `dependencies`, and `backport-skip` labels; auto-merge is disabled. |
| Permissions | Workflow defaults to `contents: read`; job grants `contents: write` and `pull-requests: write`. |
| Secrets | `SLACK_BOT_TOKEN`; `GITHUB_TOKEN`. Values are not documented here. |

## Operational notes

The composite action is shared with the previous-release workflow. Its
Updatecli configuration uses `.github/updatecli.d/bump-golang.yml`, and its
target script is `.github/updatecli.d/bump-go-version.sh`. Slack notification
uses the action's default `#ingest-notifications` channel and runs on failure.

## Sources and history

- Workflow: [`bump-golang.yml`](../bump-golang.yml)
- Composite action: [`action.yml`](../../actions/bump-golang/action.yml)
- Updatecli configuration: [`bump-golang.yml`](../../../.github/updatecli.d/bump-golang.yml)
- Update script: [`bump-go-version.sh`](../../../.github/updatecli.d/bump-go-version.sh)
- History: [`f2b6d5a`](https://github.com/elastic/golang-crossbuild/commit/f2b6d5a) automated Go version bumping; [`c7e673d`](https://github.com/elastic/golang-crossbuild/commit/c7e673d) documented auto-bump behavior.

# GitHub Actions workflows

These pages describe the checked-in workflow configuration and its local
sources. Workflows that call reusable workflows in another repository are
documented to the extent visible in their caller files.

| Workflow | Documentation |
| --- | --- |
| Go version bump for `main` | [bump-golang](docs/bump-golang.md) |
| Go version bump for the previous release branch | [bump-golang-previous](docs/bump-golang-previous.md) |
| Agentic workflow compilation check | [ci-agentic-workflows](docs/ci-agentic-workflows.md) |
| Catalog metadata validation | [catalog-info](docs/catalog-info.md) |
| Release Drafter | [release-drafter](docs/release-drafter.md) |
| Observability Agentic Workflow: status | [trigger-obs-aw-status](docs/trigger-obs-aw-status.md) |
| Observability Agentic Workflow: issue comment | [trigger-obs-aw-issue-comment](docs/trigger-obs-aw-issue-comment.md) |
| Observability Agentic Workflow: daily schedule | [trigger-obs-aw-schedule-daily](docs/trigger-obs-aw-schedule-daily.md) |
| Observability Agentic Workflow: frequent schedule | [trigger-obs-aw-schedule-frequent](docs/trigger-obs-aw-schedule-frequent.md) |
| Observability Agentic Workflow: issues | [trigger-obs-aw-issues](docs/trigger-obs-aw-issues.md) |
| Observability Agentic Workflow: pull requests | [trigger-obs-aw-pull-request](docs/trigger-obs-aw-pull-request.md) |
| Debian lifecycle monitor | [debian-lifecycle](docs/debian-lifecycle.md) |
| Build failure report | [debug-build-report](docs/debug-build-report.md) |

The Debian lifecycle and build failure report workflows are authored as
GitHub Agentic Workflow Markdown sources and compiled into the corresponding
`.lock.yml` files. The compiled workflows include generated runtime jobs.

The six Observability Agentic Workflow event callers use reusable workflow
definitions from `elastic/oblt-aw`; those remote definitions are not included
in this repository, so their internal execution is outside the scope of these
pages.

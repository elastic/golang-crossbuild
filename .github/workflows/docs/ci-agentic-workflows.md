# Agentic workflow compilation check

Checks that checked-in GitHub Agentic Workflow sources compile to the committed
workflow lock files.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`ci-agentic-workflows.yml`](../ci-agentic-workflows.yml) |
| Trigger | Pull requests targeting `main` that change selected agentic workflow sources |

## Purpose

This check prevents agentic workflow source and generated `.lock.yml` files
from drifting apart. The source and generated files are maintained together.

## When it runs

The workflow runs for pull requests targeting `main` when any of these paths
change: `.apm/**`, this workflow, `.github/workflows/*.md`,
`.github/workflows/.lock.yml`, `.github/workflows/shared/**`,
`.aw-compiler-version`, or `gh-aw.mak`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `validate` | Every matching pull request | None declared | Runs on `ubuntu-slim`, checks out the repository, and runs `make compile-aw-check`. |

The Makefile target installs the compiler version pinned in
`.aw-compiler-version`, compiles the workflow sources, then fails if generated
lock files differ from the checkout.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Pull request file changes determine whether the workflow starts. |
| Outputs | No artifacts are declared; the check validates generated files against source. |
| Permissions | Workflow grants `contents: read`. |

## Operational notes

The validation command downloads and installs the pinned `gh-aw` compiler
before compiling. No workflow or pipeline is triggered by this check.

## Sources and history

- Workflow: [`ci-agentic-workflows.yml`](../ci-agentic-workflows.yml)
- Compiler targets: [`gh-aw.mak`](../../../gh-aw.mak)
- Workflow sources: [`../`](../)
- History: [`ffa0d47`](https://github.com/elastic/golang-crossbuild/commit/ffa0d47) syncs agentic workflow files from `elastic/oblt-aw`.

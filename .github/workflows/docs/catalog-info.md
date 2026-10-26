# Catalog metadata validation

Validates changes to the repository's Backstage catalog metadata.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`catalog-info.yml`](../catalog-info.yml) |
| Trigger | Pull requests targeting `main` that change `catalog-info.yaml` |

## Purpose

The workflow runs the Elastic catalog validation action when the catalog
descriptor changes. The validation rules are implemented by the referenced
external action and are not defined in this repository.

## When it runs

The `pull_request` trigger is restricted to base branch `main` and path
`catalog-info.yaml`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `validate` | Matching pull request | None declared | Runs on `ubuntu-latest`, checks out the repository, then invokes `elastic/oblt-actions/elastic/validate-catalog@v1`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | The changed `catalog-info.yaml` file. |
| Outputs | No artifacts or outputs are declared in this workflow. |
| Permissions | Workflow grants `contents: read`; job additionally grants `packages: read`. |

## Operational notes

The external action's implementation and validation behavior are not present
in this checkout.

## Sources and history

- Workflow: [`catalog-info.yml`](../catalog-info.yml)
- Catalog descriptor: [`catalog-info.yaml`](../../../catalog-info.yaml)
- External action: [`elastic/oblt-actions`](https://github.com/elastic/oblt-actions)

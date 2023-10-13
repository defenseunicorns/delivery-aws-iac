# 11. e2e ci test scaling

Date: 2023-10-13

## Status

Accepted

Supercedes [10. e2e Testing Improvement](0010-e2e-testing-improvement.md)

## Context

Source issue: https://github.com/defenseunicorns/delivery-github-actions-workflows/issues/30

Our current implementation of reusable workflows and actions are too rigid to support the needs of various repositories. Right now our pipelines are hard coded to support multiple required status-checks and e2e tests that may not be relevant for caller repositories. For example, `test-complete-secure` or `test-complete-insecure` or `_test-on-prem-lite` may not make sense for every repo. Futhermore the current implementation doesn't scale well to add new tests or status checks for each test. These same scaling issues also exist for the pre-commit checks.

All of our pipeline logic already depends on makefile logic. We should leverage this to scale our pipelines to the needs of the caller repo.

## Decision

Have only 2 required status checks:
- pre-commit checks
- e2e-tests

For e2e testing and pre-commit checks:
- Have pipeline read the caller repo's makefile
- Find make targets starting with `ci-test-` for e2e testing jobs
- For each target, add to an array building a matrix of e2e-tests passed into the e2e test workflow to run in parallel
- Find make targets starting with `pre-commit-` for pre-commit jobs
- For each target, add to an array building a matrix of pre-commit jobs that will be passed into the pre-commit workflow to run in parallel
- After each matrix test runs, send status check of either success or failed based on return state of **all jobs** that were passed into the job matrix

Both `delivery-github-actions-workflows/.github/workflows/pr-merge-group-test.yml` (reusable workflow for merge queue testing pattern) and the caller repo's `test-command.yml` will utilize the same `e2e-test.yml` reusable workflow.

The patterns for the repos with a merge queue that utilize the `pr-merge-group-test` workflow will stay the same. Logic will be simplified to accept these inputs:

```yaml
common-e2e-test-matrix:
  description: "make target and region to run e2e tests on, must be json formatted"
  type: string
  required: false
  default: >-
    [
      {
        "make-target": "ci-test-common",
        "region": "us-east-2"
      }
    ]
release-e2e-test-matrix:
  description: "make target and region to run e2e tests on, must be json formatted, this is optional to override running all 'ci-test' make target tests"
  type: string
  required: false
e2e-required-status-check:
  description: "status check to report when e2e tests are complete"
  type: string
  required: false
  default: '["e2e-tests"]'
```

essentially, caller repos can input both or none of these and it will work. They are overridable if needed to keep our pipelines DRY.

### pr-merge-group-test.yml

`common-e2e-test-matrix`:
- This matrix of jobs will be ran always before merging into main
- Defaults to `ci-test-common`
  - Proposal: each repo's makefile will have at least a `ci-test-common` target that runs the most common e2e tests for that repo that would need to pass before merging into main

`release-e2e-test-matrix`:
- This matrix of jobs will be ran before a release is cut
- Defaults to all `ci-test-` targets in the makefile. Meaning, logic has been added to query the caller repo's makefile and find all make targets starting with `ci-test-`
  - Intention: all `ci-tests-` should pass before creating a release
  - Is overridable if needed if some tests are not relevant for a release/are redundant

`pre-commit checks`:
- This matrix of jobs will still be ran in PRs, merging into main, and before a release is cut
- Reworked a to fetch the caller repo's makefile and find all make targets starting with `pre-commit-` (excluding `pre-commit-all`)

### slash command dispatch

`/test` changes:

From a PR comment, a user with write status to the repo can:

run a single test
`/test make <make-target> region <region>`

run ping test and print debug info to the pipeline logs
`/test ping`

run all tests in the makefile beginning with `ci-test-`
`/test`

## Consequences

- Pipelines will scale to the caller repos needs if these makefile patterns are followed.
- Logic is simplified in the pipelines.
- Repo management is simplifed in the form of required status-checks being standardized.
- Hard logic is dictated by the makefile. The pipeline will report status from the inputs fed to it by the caller workflows.

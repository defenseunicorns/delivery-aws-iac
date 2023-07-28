# 7. Branch Protection Settings

Date: 2023-07-27

## Status

Accepted

## Context

We need to decide as a team what the branch protection setting will be on our repo(s).

## Decision

- We will have a Branch protection rule with the branch name pattern of `main` that contains the following settings:
  - Require pull request reviews before merging
  - Require at least 1 approving review
  - Dismiss stale pull request approvals when new commits are pushed
  - Require review from Code Owners
  - Restrict who can dismiss pull request reviews to organization and repository administrators
  - Do not allow specified actors to bypass required pull requests
  - Do not require approval of the most recent reviewable push
  - Require status checks to pass before merging
    - pre-commit status checks
    - Integration/E2E tests
  - Require conversation resolution before merging
  - Require signed commits
  - Do not require linear history
  - Do not require merge queue
  - Do not require deployments to succeed before merging
  - Do not lock the branch
  - Do not allow bypassing the above settings
  - Restrict who can push to matching branches to organization administrators, repository administrators, and users with the Maintain role only
  - Do not allow force pushes
  - Do not allow deletions

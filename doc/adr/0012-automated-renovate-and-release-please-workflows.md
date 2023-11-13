# 12. automated renovate and release-please workflows

Date: 2023-11-06

## Status

Accepted

## Context

We have many repos that have automated dependency updates, but they need manual approvals and linting after the fact in the pull requests.

These maintenance PRs need to be automated as much as possible.

## Decision

- Renovate will run less often: **weekly**
- Renovate PRs will automatically be handled by renovate-bot and narwhal-bot
  - Renovate PR workflow steps:
    - Renovate PR opened by renovate bot
    - Narwhal-bot runs pre-commit hooks for linting and documentation updates, pushes changes to renovate branch
    - Narwhal-bot modifies the repository settings' branch protection for main so that it may approve PRs (removes CODEOWNER approval requirement for the PR)
      - *Note*: you can't add bots to a team, you can't add bots to CODEOWNERS file, so we are getting hacky with repo settings
    - Narwhal-bot approves the PR via GH acttion
    - Narwhal-bot `auto-merges` PR via graph-ql mutation
    - Renovate PR gets added to merge queue
    - Workflow step queries the repo's merge queue in a loop to check if PR has been added to the queue via graph-ql
    - Narwhal-bot adds CODEOWNERs approval back to branch protection
    - PR is merged into main and closed

## Consequences

No more babysitting renovate PRs. Less maintenance overhead.
Failing code still doesn't make it into main. Merge queue pattern will kick out anything that fails tests as determined by the e2e test pipeline patterns. This will then require manual intervention.

### Risks

Need to be conscious of cloud resource quotas. Renovate needs to be configured with proper deployment windows.

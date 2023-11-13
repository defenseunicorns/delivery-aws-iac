# 12. automated renovate and release-please workflows

Date: 2023-11-06

## Status

Accepted

## Context

We have many repos that have automated dependency updates, but they need manual approvals and linting after the fact in the pullrequests.
After some code has merged into main, a release then needs to be cut via the release-please tool.
Futhermore, after we cut a release, every other repo that consumes that product then gets triggered by renovate for needing to be updated and the cycle starts over again in another repo.

This is essentially busy work. We now have sufficient automated testing in place when merging into main and cutting a release at the individual repo level.
These maintenance PRs need to be automated as much as possible.

## Decision

- renovate will run less often: **weekly**
  - Trigger times for the release-please PR to runs ideally will be randomized due to resource constraints in our AWS accounts, i.e. ran out of VPC quota, IPs, etc. and having all of those tests trigger at the same time.
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
- Releases will happen automatically by narwhal-bot
  - Release-please PR workflow steps:
    - Code is merged into main (ex. renovate PR just got merged in)
    - Release-please PR is opened (by Narwhal-bot)
    - Narwhal-bot modifies the repository settings' branch protection for main so that it may approve PRs (removes CODEOWNER approval requirement for the PR)
      - *Note*: you can't add bots to a team, you can't add bots to CODEOWNERS file, so we are getting hacky with repo settings
    - Narwhal-bot approves the PR via GH acttion
    - Narwhal-bot `auto-merges` PR via graph-ql mutation
    - Renovate PR gets added to merge queue
    - Workflow step queries the repo's merge queue in a loop to check if PR has been added to the queue via graph-ql
    - Narwhal-bot adds CODEOWNERs approval back to branch protection
    - PR is merged into main and closed
    - Release-please triggers and cuts a new release
      - *Note* If this release is a dependency of another one of our repos, renovate will pick it up in its workflow, and the cycle starts over :smile:
    - **Releases will only happen when:** terraform specific code has changed outside of the `/examples` directory. It doesn't make sense to cut a release for something that is going to affect other modules that consume it if it the changes aren't relevant to the usage of the module itself.

## Consequences

No more babysitting renovate PRs or release-please PRs. Less maintenance overhead.
Repos are treated more as cattle.
Development time can be focused on implementing features and working issues instead of babysitting bot PRs (in the correct order.)
Failing code still doesn't make it into main. Merge queue pattern will kick out anything that fails tests as determined by the e2e test pipeline patterns. This will then require manual intervention.

### Risks

Need to be conscious of cloud resource quotas. We could potentially have all of our repos triggering during the same window, each running multiple tests if configured to do so.

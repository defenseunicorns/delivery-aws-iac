# 9. Automated Release Process

Date: 2023-07-27

## Status

Accepted

## Context

We need to decide as a team how we will do releases for this repo. We have a few options:

- Do a SemVer version on every push to main
- Do a CalVer version on every push to main (something like `vYYYYMMDDss`)
- Do a SemVer version periodically
- Do a CalVer version periodically

We also need to decide how we will do the releases. The current options being discussed are:

- A GitHub Actions workflow that creates a tag
- The ReleasePlease bot

## Decision

- We will do a SemVer version periodically, with no fixed release cadence. We will release when we feel it is important to do so.
- We will set up a GitHub Action that runs every day that alerts us via Slack if a release has not been made in the last 14 days.
- We will use the ReleasePlease bot to do the releases.
- We will delete any CalVer tags that are present in the repo so that ReleasePlease doesn't try to use them to determine the next version.

Why:
- We don't want to release on every commit to main because sometimes small commits to main to not warrant new releases.
- We want to set up an automated test that tests the upgrade path between the last release and the latest commit to main. If releases are happening too frequently, this type of test becomes far less useful.
- We want to use SemVer because it gives any consumer a better understanding of what happened in the release
- We want to use ReleasePlease because it will help us automate good habits of maintaining a changelog and good release notes.

## Consequences

- Maintainers will need to use [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/) messages when merging PRs for ReleasePlease to work properly.
- We will need to set up a GitHub Action that runs on commits to main that alerts us via Slack if a commit is made to main that does not conform to the Semantic Commit format.

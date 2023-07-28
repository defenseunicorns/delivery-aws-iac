# 8. How To Trigger Automated Tests

Date: 2023-07-27

## Status

Accepted

## Context

We need to decide as a team how tests should be triggered, whether automatically, manually or both.

### Our Options

1. Use manual test triggers using Slash Command Dispatch.
1. Run automatically on a variety of `pull_request` events
1. A combination of manual triggers using Slash Command Dispatch and autoomatic triggers

## Decision

- We will automatically trigger the tests if and only if all the following conditions are met:
  - The author of the pull request is Renovate
  - The pull request was just opened (i.e., it should only ever run automatically once per pull request)
> This allows us to quickly merge Renovate PRs that were created overnight without having to wait for the tests to finish after a manual trigger.
- Otherwise, the tests will be triggered manually by a person by adding a comment to the PR that says `/test <test-name>`. Most of the time that will be `/test all` but there will likely be times when we may want to run a specific test, in which case we would use something like `/test e2e-commercial-insecure`
> This lets us minimize the number of unnecessary tests we run.
- We will stop running the tests on every commit to main.
> Since [ADR #7](./0007-branch-protection-settings.md) was accepted, we will no longer be able to merge to main without a successful test run. So there is no need to run the tests on every commit to main.

## Consequences

### Pros
- We will have more control over when it is appropriate to execute a test as some tests will cost real infrastructure $$$.
- We can easily manually trigger subsequent tests as discussion is had and changes are made.
- 3rd party contributors who are submitting PRs from fork may fully participate in the development process.

### Cons
- It requires human interaction to run the tests, which will likely increase our development cycle times a small amount.

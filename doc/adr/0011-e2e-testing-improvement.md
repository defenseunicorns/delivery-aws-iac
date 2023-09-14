# 11. e2e testing improvement

Date: 2023-09-14

## Status

Accepted

Supersedes [10. e2e Testing Improvement ADR](0010-e2e-testing-improvement.md)

## Context

e2e testing is crucial for ensuring that our IaC (Infrastructure as Code) is functional and robust. However, there are aspects of the current e2e testing workflow that we can improve to make it more efficient and effective. This ADR outlines these proposed enhancements.

## Decision

- Workflows should be `skipped` if no relevant files have changed; otherwise, run the tests.
  - We will use the [paths-filter](https://github.com/dorny/paths-filter) GitHub Action to conditionally execute workflow steps and jobs based on the files modified.
  - **Note**: Jobs that are `skipped` will still report "Success" as their status, so they won't block pull requests even if they are marked as required checks.
- In a PR we are able to run both insecure and secure tests
  - Tests are not required to pass to be added to merge queue
  - Maintainers can use slash command dispatch
- The E2E Insecure test is required in to pass in `merge_group` event. This will ensure only code that passes this test is merged to main.
- The E2E Secure test is required to run at least nightly and be integrated with slack notification
  - This maintains successful deployment validation for our target environments
  - Resolving failures must become the top priority of the iac team
- Release Please PR should not be added to the merge queue unless the merge queue is empty. Release please needs to be at the head of the queue, else it will miss other commits to main in its commit to the CHANGELOG.md file.
- Release Please PRs will run both tests to ensure that all tests pass before a tag is cut. Ensures that releases will be valid.

## Consequences

### What Becomes Easier

- Developers will spend less time waiting for irrelevant or redundant tests to pass.
- Resources will be used more efficiently, cutting down costs and time.

### What Becomes More Difficult

- Initial setup of the custom GitHub logic and workflow adjustments will require some time and expertise.

### Risks

- Custom logic for triggering tests could have bugs that may require additional troubleshooting.

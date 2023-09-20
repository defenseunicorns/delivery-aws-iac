# 10. e2e Testing Improvement

Date: 2023-09-14

## Status

Accepted

Supersedes [08. how to trigger automated tests](0008-how-to-trigger-automated-tests.md)

## Context

End-to-end (e2e) testing is a crucial component for validating the robustness and functionality of our Infrastructure as Code (IaC). While our current e2e testing workflow does the job, there are opportunities for making it more efficient and effective. This ADR aims to address various issues like test redundancy, inefficient triggering of tests, and the efficacy of secure tests.

### Only Run e2e Tests if Code-related Files Have Updated

1. **Skip Unnecessary Runs**: Running e2e tests for changes that don't affect the code (e.g., updating READMEs) is inefficient.
    - To achieve this, we'll need to add custom logic to our GitHub workflows, as GitHub's branch protection rules and required status checks do not offer this granularity.

2. **Conditional Workflows**: Workflows should be `skipped` if no relevant files have changed; otherwise, run the tests.
    - **Implementation Plan**: Use the [paths-filter](https://github.com/dorny/paths-filter) GitHub Action to conditionally execute workflow steps and jobs based on the files modified.
    - **Note**: Jobs that are `skipped` will still report "Success" as their status, so they won't block pull requests even if they are marked as required checks.

### Revise or Change how we run the Secure Test

The secure test takes significantly longer to complete compared to the insecure test, doubling the time required for e2e tests to complete.

1. **Relevance of Secure Test**: It's important to consider what the secure test is verifying about our IaC that isn't covered by the insecure test.
    - Is it the deployment pattern, the cloud environment, or the instance types that make it essential? The private eks endpoint pattern is essential to match our target environments.

If we only utilize public EKS endpoints for pipeline purposes, our e2e tests will run much faster, eliminating the need for sshuttle and multiple Terraform setup & apply cycles in terratest.

### Avoid Duplication of Required Test Passing

1. **Optimize Testing**: Having to pass all tests twice—once for the pull request and once before (merge queue) or after merging into `main`—seems redundant.

### Leverage Merge Queue Feature

1. **Streamline e2e Testing with Merge Queue**: We can optimize our testing process by integrating it with the merge queue.
    - **Implementation Plan**: A workflow triggered on `pull request` will either skip the e2e test status checks or succeed them, followed by the actual tests running in the `merge_group` workflow.

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

- Developers experience fewer delays as irrelevant or redundant tests are skipped.
- Efficient use of resources, both time and compute, leading to cost savings.

### What Becomes More Difficult

- Initial setup of the refined GitHub logic and any new workflows will need extra time and technical acumen.

### Risks

- The custom logic for triggering tests could introduce bugs, necessitating additional debugging.
- Altering the "secure test" needs a comprehensive review to ensure that it doesn't compromise the quality of our IaC.

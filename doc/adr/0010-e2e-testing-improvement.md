# e2e Testing Improvement ADR

## Context
e2e testing is crucial for ensuring that our IaC (Infrastructure as Code) is functional and robust. However, there are aspects of the current e2e testing workflow that we can improve to make it more efficient and effective. This ADR outlines these proposed enhancements.

## Only Run e2e Tests if Code-related Files Have Updated

1. **Skip Unnecessary Runs**: Running e2e tests for changes that don't affect the code (e.g., updating READMEs) is inefficient.
    - To achieve this, we'll need to add custom logic to our GitHub workflows, as GitHub's branch protection rules and required status checks do not offer this granularity.

2. **Conditional Workflows**: Workflows should be `skipped` if no relevant files have changed; otherwise, run the tests.
    - **Implementation Plan**: Use the [paths-filter](https://github.com/dorny/paths-filter) GitHub Action to conditionally execute workflow steps and jobs based on the files modified.
    - **Note**: Jobs that are `skipped` will still report "Success" as their status, so they won't block pull requests even if they are marked as required checks.

## Revise or Get Rid of Secure Test

The secure test takes significantly longer to complete compared to the insecure test, doubling the time required for e2e tests to complete.

1. **Relevance of Secure Test**: It's important to consider what the secure test is verifying about our IaC that isn't covered by the insecure test.
    - Is it the deployment pattern, the cloud environment, or the instance types that make it essential?

If we only utilize public EKS endpoints for pipeline purposes, our e2e tests will run much faster, eliminating the need for sshuttle and multiple Terraform setup & apply cycles in terratest. We can document "secure mode" as a separate use-case if needed.

## Avoid Duplication of Required Test Passing

1. **Optimize Testing**: Having to pass all tests twice—once for the pull request and once before (merge queue) or after merging into `main`—seems redundant.

### Leverage Merge Queue Feature

1. **Streamline Testing with Merge Queue**: We can optimize our testing process by integrating it with the merge queue.
    - **Implementation Plan**: A workflow triggered on `pull request` will either skip the e2e test status checks or succeed them, followed by the actual tests running in the `merge_group` workflow.

## Consequences

### What Becomes Easier

- Developers will spend less time waiting for irrelevant or redundant tests to pass.
- Resources will be used more efficiently, cutting down costs and time.

### What Becomes More Difficult

- Initial setup of the custom GitHub logic and workflow adjustments will require some time and expertise.

### Risks

- Custom logic for triggering tests could have bugs that may require additional troubleshooting.
- Any removal or significant alteration of the "secure test" needs to be fully understood to ensure it doesn't compromise the quality of our IaC.

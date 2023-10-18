# Contributor Guide

Thanks so much for wanting to help out! :tada:

Most of what you'll see in this document is our attempt at documenting the lightweight development process that works for our team. We're always open to feedback and suggestions for improvement. The intention is not to force people to follow this process step by step, rather to document it as a norm and provide a baseline for discussion.

## Developer Experience

Continuous Delivery is core to our development philosophy. Check out [https://minimumcd.org](https://minimumcd.org/) for a good baseline agreement on what that means.

Specifically:

- We do trunk-based development (`main`) with short-lived feature branches that originate from the trunk, get merged to the trunk, and are deleted after the merge.
- We don't merge work into `main` that isn't releasable.
- We perform automated testing on all pushes to `main`. Fixing failing pipelines in `main` are prioritized over all other work.
- We create immutable release artifacts.

### Developer Workflow

:key: == Required by automation

1. Pick an issue to work on, assign it to yourself, and drop a comment in the issue to let everyone know you're working on it.
2. Create a Draft Pull Request targeting the `main` branch as soon as you are able to, even if it is just 5 minutes after you started working on it. We lean towards working in the open as much as we can. If you're not sure what to put in the PR description, just put a link to the issue you're working on. If you're not sure what to put in the PR title, just put "WIP" (Work In Progress) and we'll help you out with the rest.
3. :key: The automated tests have to pass for the PR to be able to be merged. To run the tests in the PR add a comment to the PR that says `/test`. **NOTE** tests still have to pass in the merge queue, **you do not need to have tests pass in the PR, status checks are automatically reported as success in the PR**. If you want to run a specific test manually in the PR, you can use `/test make=<make-target> region=<region>`. The available CI tests are found in the [Makefile](./Makefile) and start with the string "ci-test-"
4. If your PR is still set as a Draft transition it to "Ready for Review"
5. Get it reviewed by a [CODEOWNER](./CODEOWNERS)
6. Add the PR to the merge queue
7. The merge queue will run different tests based on if it's a `release-please` pull request or just a regular pull request. If it's a `release-please` pull request, it will run all make target `ci-test-`s by default. If it's a regular pull request, it will run the `ci-test-common` test by default. If the tests fail, the PR will be removed from the merge queue and the PR stays open. If the tests pass, the PR will be merged to `main` and the PR will be closed.
8. If the issue is fully resolved, close it. _Hint: You can add "Closes #XXX" to the PR description to automatically close the issue when the PR is merged._

### Pre-Commit Hooks

This project uses [pre-commit](https://pre-commit.com/) to run a set of checks on your code before you commit it. You have the option to either install pre-commit and all other needed tools locally or use our docker-based build harness. To use the build harness, run

```shell
make run-pre-commit-hooks
```
> NOTE: Sometimes file ownership of stuff in the `.cache` folder can get messed up. You can optionally add the `fix-cache-permissions` target to the above command to fix that. It is idempotent so it is safe to run it every time.

### Commit Messages

Because we use the [release-please](https://github.com/googleapis/release-please) bot, commit messages to main must follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This is enforced by the [commitlint](https://commitlint.js.org/#/) tool. This requirement is only enforced on the `main` branch. Commit messages in PRs can be whatever you want them to be. "Squash" mode must be used when merging a PR, with a commit message that follows the Conventional Commits specification.

### Release Process

This repo uses the [release-please](https://github.com/googleapis/release-please) bot. Release-please will automatically open a PR to update the version of the repo when a commit is merged to `main` that follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. The bot will automatically keep the PR up to date until a human merges it. When that happens the bot will automatically create a new release.

### Backlog Management

- We use [GitHub Issues](https://github.com/defenseunicorns/delivery-aws-iac/issues) to manage our backlog.
- Issues need to meet our Definition of Ready (see below). If it does not meet the Definition of Ready, we may close it and ask the requester to re-open it once it does.

#### Definition of Ready for a Backlog Item

To meet the Definition of Ready the issue needs to answer the following questions:
- Who is requesting it?
- What is being requested?
- Why is it needed?
- What is the impact? What will happen if the request is not fulfilled?
- How do we know that we are done?

This can take various forms, and we don't care which form the issue takes as long as it answers the questions above.

# 3. Move tfstate-backend module to separate repo

Date: 2023-02-21

## Status

Accepted

## Context

As we start moving more toward treating our Terraform infrastructure code as a product, additional focus is needed on making each module into an independently consumable product. This means that each module should:

* Be versioned independently
* Run automated tests
* Have sufficient documentation

## Decision

To assist with being versioned independently, we will move the `tfstate-backend` module to a [separate repository](https://github.com/defenseunicorns/terraform-aws-tfstate-backend). This will allow us to develop and release new versions of the module independently of the rest of the infrastructure code.

This decision is, for now, just being made for the `tfstate-backend` module. We will evaluate other modules for similar treatment in the future as we uncover better ways and best practices for managing reusable production-level Terraform work.

## Consequences

What becomes easier or more difficult to do and any risks introduced by the change that will need to be mitigated.

* It will be easier to version the module independently of the rest of the infrastructure code.
* It will be easier to run automated tests on the module since we won't need any custom logic to figure out when certain tests can be skipped (e.g. when this module has not been changed but another has, only run the other module's tests)
* Our work will be less DRY (Don't Repeat Yourself) since each independent module repo will need its own set of GitHub Actions workflows/scripts/Makefile, etc. This can potentially be mitigated by using automation to keep code that is the same across all modules in sync.

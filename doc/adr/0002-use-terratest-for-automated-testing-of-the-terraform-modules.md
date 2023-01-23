# 2. Use Terratest for automated testing of the Terraform modules

Date: 2023-01-23

## Status

Accepted

## Context

We need a way to automatically test the Terraform modules that we create. 2 options were suggested:

* [Terratest](https://github.com/gruntwork-io/terratest) -- A golang library from Gruntwork
* [terraform-testing](https://github.com/antonbabenko/terraform-testing) -- A project by Anton Babenko, that now looks to have been either abandoned or moved

## Decision

For the time being we will use Terratest for automated testing of the Terraform modules until such time that a different option is selected at a company-wide level.

## Consequences

* Terratest is already used in other areas in the company (namely [DI2-ME](https://github.com/defenseunicorns/zarf-package-software-factory)) so it should be easier to adopt as we can copy/paste existing work.


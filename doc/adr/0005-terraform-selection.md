# 5. Use Terraform for IaC

Date: 2023-05-05 (Effective 2023-01-02)

## Status

Accepted

## Context

We need to select a tool for Infrastructure as Code that:

* establish a common pattern across multiple environments (on prem, cloud providers, etc.)
* is portable
* is widely supported
* can be easily adopted / extended by external entities running day 2 ops
* is extensible for internal use cases
* doesn't introduce significant complexity / unnecessary cost

Tools that were considered:

* Pulumi
* Crossplane
* Terragrunt
* Terraform
* CDKTF

## Decision

We chose Terraform because
  - it is the most widely adopted IaC tool (we felt it would resonate best with external day 2 ops partners)
  - it is portable (easily supports air gapped environments)
  - allowed us to leverage existing capabilities / experience (expedited delivery of capabilities)
  - didn't introduce additional complexity (minimal dependencies)
  - could be converted to a more versatile language via CDKTF
  - easily tested in pipelines
  - easily deployable with zarf

Why we didn't choose one of the other tools:

* Pulumi
  - limited engineering experience internally (with an assumption that many day 2 ops teams would also have this)
  - delivery time constraints
  - not as widely supported

* Crossplane
  - requires a utility cluster / hub and spoke architecture (chicken and egg scenario)
    - incurs additional cloud costs - many DoD environments require dedicated tenancy which is x3 more expensive
    - add significant complexity to mission environments and e2e testing pipelines
  - portability concerns
  - adoption / extsensibility concerns  
  - not as widely supported


* Terragrunt (we intentionally refactored away from terragrunt because)
  - zarf is effectively a wrapper for terraform and could handle those functions eventually&trade;
  - it didn't feel like this was the right layer to opionate / abstract from
  - additional complexity in maintaining both terraform modules and a highly opinionated terragrunt folder structure
  - compatibility issues with some opinionated upstream modules

* CDKTF
  - limited engineering experience internally (with an assumption that many day 2 ops teams would also have this)
  - only supports cloud providers
  - not as widely supported
  - because we chose terraform, there is an option to migrate to this at a later time

## Consequences

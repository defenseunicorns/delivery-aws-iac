# 13. Opinionated Tofu AWS Wrapper Modules

Date: 2024-10-01

## Status

Proposed

## Context

We have a collection of Defense Unicorns terraform modules that wrap official AWS modules. We want these modules to be more opinionated such that new missions and product workflows can consume them quickly and understand context for the design.

At a high level what questions do we need to ask when using Tofu to bootstrap infrastructure on a new mission.

- Cloud (AWS, Azure, etc...)
- Impact Level (DoD Cloud Computing requirements: IL4, IL5, etc...)
- k8s platform (eks, k0s, k3s)
- Network Type (Air-Gapped, Partially Isolated, Open)

Modules with defaults based on this context for these needs allow for informed, standardized choices.

We'll focus on the modules used by the reference deployments and collaborate with Delivery org technical leads to streamline choices and associate defaults to mission contexts.

Initial modules:

- https://github.com/defenseunicorns/terraform-aws-vpc
- https://github.com/defenseunicorns/terraform-aws-bastion
- https://github.com/defenseunicorns/terraform-aws-eks

## Decision

We will...

- [Prefer single objects over multiple simple inputs for related configuration](https://docs.cloudposse.com/best-practices/terraform/#prefer-a-single-object-over-multiple-simple-inputs-for-related-configuration)
  - Organize wrapper module vars by what's required versus optional with secrets broken out.
  ```
  variable "eks_required_var1" {}
  variable "eks_required_var2" {}
  variable "eks_sensitive_required_var1" {
    sensitive = true
  }
  variable "eks_config_opts" {
    type = object({
      eks_opt1 = optional(string)
      eks_opt2 = optional(string)
    })
  }
  variable "eks_sensitive_config_opts" {
    sensitive = true
    type = object({
      eks_sensitive_opt1 = optional(string)
      eks_sensitive_opt2 = optional(string)
    })
  }
  ```
  - Make it clear to the consumer what's required and intended for them to decide for the mission.
  - Don't mix secrets with non-secrets to aid in troubleshoot. Mixing will mask non-secret data in
    deployment output.
  - NOTE: Do we want to take on the scope to keep secrets in a store and out of module output? (require a store as input)
- Use [Cloud Posse context provider](https://github.com/cloudposse/terraform-provider-context/)
  - for shared context between modules and applies
  - common attributes such as name prefix/suffix (labels), tags and other global configuration.
- Avoid directly passing attributes to wrapped modules in favor of defaults organized by context.
  - Used Impact Level based defaults

An example of the data flow through modules connected via a stack is provided [here](../../atmos). You can see how in
lieu of vars for name prefixes, tags and other global config the context is used.

By requiring the context provider in the wrapper module.

```
terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
  }
}
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}
```

context labels and tags are used for resources.

```
module "aws_eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.24.0"

  cluster_name    = data.context_label.this.rendered
  tags            = data.context_tags.this.tags


```

Note that the Cloud Posse tool [Atmos](https://atmos.tools/) provides a workflow for organizing terraform as components
that are assembled in stacks. Atmos a high level is a combination of a templating engine driven by config files that renders
tofu [variable files](https://opentofu.org/docs/v1.7/language/values/variables/#variable-definitions-tfvars-files) and
[override files](https://opentofu.org/docs/v1.7/language/files/override/).
This allows for DRY assembly of stacks which enable chaining
of multiple tofu IaC deployments with a "Kustomize-like" overlay workflow for overriding a catalog of
opinionated deployments. While the wrapper module refactor does not require atmos, it's worth understanding
its workflow. Atmos provides significant guidance for organizing a catalog of reference deployments.

## Consequences

Bootstrapping new missions becomes context driven by standards put in place by impact level. It's clear why one is choosing configuration options.

We do run the risk of not exposing the appropriate config options for new missions. The use of parameter objects patterns is there to mitigate that risk.

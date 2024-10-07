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

- Make it clear to the consumer what's required and what's intended for them to decide for the mission.
  - We want to avoid modules that take on the responsibility of being flexible to what may or may not be needed downstream of their deployment.
    This doesn't mean we don't what this flexibility, it means it should live outside of architectural modules. For example, selection of Availability Zones may be a mission decision
    based on capabilities needed at the EKS layer, but decision needs to be deployed at VPC layer.
    We can provide a `mission-init` module that can help dynamically select Availability Zones, instance types, etc... This approach may also be used to help organize what should be decided up
    front based on mission requirements.
  - This is one of the motivations for adding context and more opinions. Another example, VPCs may
    need to know the name of the EKS cluster before the cluster is created in order to set tags
    for internal load balancing. The context makes the names deterministic.
- Add one layer with Defense Unicorns opinions around official AWS modules. (Don't wrap our wrappers)
- Organize wrapper module vars by what's required versus optional with secrets broken out.
  - Use high level cloud ownership context to guide breakdown of top level config object parameters.
    Make it obvious where to start with settings related to the following.
    - IAM
    - Compute
    - Networking
    - Observability
    - Storage
    - Security
    - UDS
- Set defaults based on Impact Level using overrides from a base.
- Allow for config defaults to be selected from criteria such as impact level from the global context.
- Organize locals for context based configs into separate file such that
  CODEOWNERS can be use to keep SME's in the loop.
- [Prefer single objects over multiple simple inputs for related configuration](https://docs.cloudposse.com/best-practices/terraform/#prefer-a-single-object-over-multiple-simple-inputs-for-related-configuration)
- Don't mix secrets with non-secrets to aid in troubleshoot. Mixing will mask non-secret data in
  deployment output.
- Use [Cloud Posse context provider](https://github.com/cloudposse/terraform-provider-context/)
  - for shared context between modules and applies
  - common attributes such as name prefix/suffix (labels), tags and other global configuration.
- Avoid directly passing attributes to wrapped modules in favor of defaults organized by context.

- Example

  ```
  // Context data sources that spans modules and deploys.
  data "context_config" "this" {}
  data "context_label" "this" {}
  data "context_tags" "this" {}

  // Standardize on config objects. Use `optional()` to set defaults as needed.
  variable "vpc_config" {
    description = "Existing VPC configuration for EKS"
    type = object({
      vpc_id                     = string
      subnet_ids                 = list(string)
      azs                        = list(string)
      private_subnets            = list(string)
      intra_subnets              = list(string)
      database_subnets           = optional(list(string))
      database_subnet_group_name = optional(string)
    })
  }

  // EKS configuration options. We can put in defaults, however defaults
  // should not be provided for items that need to be a mission decision.
  variable "eks_config_opts" {
    description = "EKS Configuration options to be determined by mission needs."
    type = object({
      cluster_version = optional(string, "1.30")
    })
  }

  variable "eks_sensitive_config_opts" {
    sensitive = true
    type = object({
      eks_sensitive_opt1 = optional(string)
      eks_sensitive_opt2 = optional(string)
    })
  }

  locals {
    base_eks_config = {
      vpc_id                               = var.vpc_attrs.vpc_id
      subnet_ids                           = var.vpc_attrs.subnet_ids
      tags                                 = data.context_tags.this.tags
      cluster_name                         = data.context_label.this.rendered
      cluster_version                      = var.eks_config_opts.cluster_version
      control_plane_subnet_ids             = var.vpc_attrs.private_subnets
      private_subnet_ids                   = var.vpc_attrs.private_subnets
      iam_role_permissions_boundary        = data.context_config.this.values["PermissionsBoundary"]
      cluster_endpoint_public_access       = true
      cluster_endpoint_public_access_cidrs = []
      cluster_endpoint_private_access      = false
      self_managed_node_group_defaults     = {}
      self_managed_node_groups             = []
      cluster_addons                       = []
    }
    il4_eks_overrides = {
      cluster_endpoint_public_access  = false //No public access for >= IL4
      cluster_endpoint_private_access = true  //Private access required for >= IL4
    }
    il5_eks_overrides = merge(local.il4_eks_overrides, {}) // IL5 extends IL4
    il4_eks_config    = merge(local.base_eks_config, local.il4_eks_overrides)
    il5_eks_config    = merge(local.base_eks_config, local.il5_eks_overrides)
    eks_config = {
      base  = local.base_eks_config,
      il4   = local.il4_eks_config,
      il5   = local.il5_eks_config
    }
  }

  //Use Impact Level from context to set the default config for EKS
  // This object will be used to configure the official AWS EKS module.
  // Outputting for illustration purposes.
  output "eks_config" {
    value = local.eks_config[data.context_config.this.values["impact_level"]]
  }

  ```

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

We will not...

- Take on the scope to keep secrets in a store and out of module output.
  - It's best practices to keep secrets out of tofu state (in favor of pointers to their location in a secret store).
  - This can be addressed in a future ADR.

Note that the Cloud Posse tool [Atmos](https://atmos.tools/) provides a workflow for organizing terraform as components
that are assembled in stacks. Atmos a high level is a combination of a templating engine driven by config files that renders
tofu [variable files](https://opentofu.org/docs/v1.7/language/values/variables/#variable-definitions-tfvars-files) and
[override files](https://opentofu.org/docs/v1.7/language/files/override/).
This allows for DRY assembly of stacks which enable chaining
of multiple tofu IaC deployments with a "Kustomize-like" overlay workflow for overriding a catalog of
opinionated deployments. While the wrapper module refactor does not require atmos, it's worth understanding
its workflow. Atmos provides significant guidance for organizing a catalog of reference deployments.

To use `atmos` to see the data flow for the module refactor. Note: you'll need AWS creds to run the plan.

```
cd atmos
atmos  workflow plan-eks --file eks.yaml --from-step="init"
```

## Consequences

Bootstrapping new missions becomes context driven by standards put in place by impact level. It's clear why one is choosing configuration options.

We do run the risk of not exposing the appropriate config options for new missions. The use of parameter objects patterns is there to mitigate that risk.

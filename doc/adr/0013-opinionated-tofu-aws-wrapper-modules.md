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

- https://github.com/defenseunicorns/terraform-aws-uds-vpc
- https://github.com/defenseunicorns/terraform-aws-uds-bastion
- https://github.com/defenseunicorns/terraform-aws-uds-eks

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
  - This layer shall be highly opinionated. We'll be removing most choices in favor of "classes" of settings
    based on context.
  - All defaults for the official aws module shall be captured in a single file. (i.e.: `locals-defaults-terraform-aws-vpc.tf`).
    This enables programmatic updates from the source module and ensures that defaults do not get changed out from under us.
  - We'll be removing most options in favor of decisions. This doesn't mean we can't add flexibility later, but we will start with stronger opinions with options based on UDS bundle needs. Examples...
    - Kubernetes version shall be fixed in the module.
    - Node group options will be fixed for core (specific instances labeled for Keycloak sso)
    - Providing public access for bundle development or impact level 2 shall be via a transit gateway into
      an IL5 private deployment.
    - GPU node group for EKS based on LeapfrogAI requirements is still a conditional option.
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

We will not...

- Take on the scope to keep secrets in a store and out of module output.
  - It's best practices to keep secrets out of tofu state (in favor of pointers to their location in a secret store).
  - This can be addressed in a future ADR.

## Design Patterns

- Context is set by the context provider and used for resource names and tags.
- Defaults for wrapped modules are explicitly set such that they cannot change out from under us.
  - Each module shall have it's own file to set a local object with default settings.
  - The names of the attributes much match the names from the wrapped module.
  - File name: `locals-defaults-<MODULE_NAME>.tf`
    ```
    locals {
      <MODULE_NAME>_defaults = {
        # Defaults generated from wrapped module
        # terraform-docs --sort-by required json ${path} | jq -r '.inputs[]|.name + " = " + if (.type == "string" and .default != null) then "\"" + .default + "\"" else (.default| tostring) end'
      }
      keycloak_config_defaults = {
        kms_config = local.aws_kms_defaults
        db_config  = local.aws_rds_defaults
      }
    }
    ```
- Defense Unicorn opinions are organized by context. Impact Level shall be used for initial context with a default of IL5.

  - Context based overrides shall have their own files and broken down into subcategories and context as needed.
    When breaking into subcategories or contexts they should organize such that codeowners is used for maintainability.
  - File name: `locals-overrides-<MODULE_NAME>-<SUBCATEGORY>-<CONTEXT>.tf`

    ```
    locals {
      <CONTEXT>_<MODULE_NAME>_<SUBCATEGORY>_overrides = {
         # Overrides should strive to match the attribute names of the modules they wrap as much as possible.
      }

      base_uds_keycloak_overrides = {
        db_config  = {
          # Attribute names match those needed for the wrapped RDS module
        }
        kms_config = {
          # Attribute names match those needed for the wrapped KMS module
          description = "UDS Keycloak Key"
        }
        tags = data.context_tags.this.tags
        # other wrapper module attributes.
       }
    }
    ```

- Advance overrides variable shall be provided to allow runtime override of context based settings.
  - Consumers with advanced understanding of wrapped modules and override data structures can change
    settings directly without the wrapper module having to expose everything inside.
  - TF var file
    ```
    advanced_overrides = {
      kms_config = {
        description = "Override Keycloak Key Description"
      }
    }
    ```
- Overrides Deep merge
  - A deep merge of Defaults <- Context based overrides <- advanced overrides variable is performed
    before passing attributes to wrapped modules and resources.
    ```
    locals {
      context_key = "impact_level"
      keycloak_config_contexts = {
        base = [local.base_uds_keycloak_overrides, ]
        il4 = [local.base_uds_keycloak_overrides, ]
        il5 = [local.base_uds_keycloak_overrides, ]
        devx = [local.base_uds_keycloak_overrides, local.devx_overrides]
      }
      context_overrides = local.keycloak_config_contexts[data.context_config.this.values[local.context_key]]
      uds_keycloak_config = module.config_deepmerge.merged
    }
    module "config_deepmerge" {
      source  = "cloudposse/config/yaml//modules/deepmerge"
      version = "0.2.0"
      maps = concat(
        [local.keycloak_config_defaults],
        local.context_overrides,
        [var.advanced_overrides],
      )
    }
    ```
- Wrapped Module configuration

  - Wrapped modules are configured with the merged defaults, context overrides and advanced overrides.
    ```
    module "kms" {
      source                   = "terraform-aws-modules/kms/aws"
      version                  = "3.1.0"
      description              = local.uds_keycloak_config.kms_config.description
      deletion_window_in_days  = local.uds_keycloak_config.kms_config.deletion_window_in_days
      enable_key_rotation      = local.uds_keycloak_config.kms_config.enable_key_rotation
      policy                   = data.aws_iam_policy_document.kms_access.json
      multi_region             = local.uds_keycloak_config.kms_config.multi_region
      key_owners               = local.uds_keycloak_config.kms_config.key_owners
      tags                     = local.uds_keycloak_config.kms_config.tags
      create_external          = local.uds_keycloak_config.kms_config.create_external
      key_usage                = local.uds_keycloak_config.kms_config.key_usage
      customer_master_key_spec = local.uds_keycloak_config.kms_config.customer_master_key_spec
    }
    ```

- Wrapper modules inputs

  - Use objects to organize classes of settings.
    - Sensitive data shall not be mixed with non-sensitive data in objects.
    - All sensitive data must be flagged as such.
  - Use context for tagging and resource labels.

    ```
    terraform {
      required_providers {
        context = {
          source  = "registry.terraform.io/cloudposse/context"
          version = "~> 0.4.0"
        }
      }
    }
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
    module "aws_eks" {
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.24.0"
      cluster_name    = data.context_label.this.rendered
      tags            = data.context_tags.this.tags
    }
    ```

- Wrapper modules outputs

  - Use single object to output all non-sensitive data
    - Sensitive outputs should be grouped together and flagged as being sensitive
  - Only output information deemed necessary for other modules to consume
  ```
  output "vpc_properties" {
    description = "Configuration of the VPC including subnet groups, subnets, and VPC ID"
    value = {
      azs                         = module.vpc.azs
      database_subnet_group_name  = module.vpc.database_subnet_group_name
      database_subnets            = module.vpc.database_subnets
      intra_subnets               = module.vpc.intra_subnets
      private_subnets             = module.vpc.private_subnets
      private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
      public_subnets              = module.vpc.public_subnets
      vpc_id                      = module.vpc.vpc_id
    }
  }
  ```

- Input and Output naming

  - Variables should be named:
    - `<module>-options`
      - For optional inputs
    - `<module>-requirements`
      - For required inputs
    - `<module>-advanced-overrides`
      - For advanced variable overrides
    - `<module>-properties`
      - For module outputs

An example of the data flow through modules connected via a stack is provided [here](../../atmos). You can see how in
lieu of vars for name prefixes, tags and other global config the context is used.

Note that the Cloud Posse tool [Atmos](https://atmos.tools/) provides a workflow for organizing terraform as components
that are assembled in stacks. Atmos at a high level is a templating engine driven by config files that renders
tofu [variable files](https://opentofu.org/docs/v1.7/language/values/variables/#variable-definitions-tfvars-files) and
[override files](https://opentofu.org/docs/v1.7/language/files/override/).
This allows for DRY assembly of stacks which enable chaining
of multiple tofu IaC deployments with a "Kustomize-like" overlay workflow for overriding a catalog of
opinionated deployments. While the wrapper module refactor does not require atmos, it's worth understanding
its workflow. Atmos provides significant guidance for organizing a catalog of reference deployments.

[`atmos`](https://atmos.tools) provides some guard rails as we work on the refactor. However, there are no requirements for it to be used to consume these modules. Note: you'll need AWS creds to run the plan.

```
cd atmos
atmos  workflow plan-eks --file dev.yaml
```

## Consequences

Bootstrapping new missions becomes context driven by standards put in place by impact level. It's clear why one is choosing configuration options.

We do run the risk of not exposing the appropriate config options for new missions. The `advanced_overrides` pattern mitigates that risk.

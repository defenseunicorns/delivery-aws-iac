# 4. Selection Criteria for Upstream Terraform Modules

Date: 2023-05-11 (Effective 2023-01-02)

## Status

Accepted

## Context

Why / How were opinionatation decisions made for this project

Guiding Principles:
* AWS is the target environment
* zarf will be the GitOps mechanism for IaC
* IL5 controls are met
* make it simpler to deploy / update *the same* zarf package (base) across multiple environments
  - extensible to & for dev -> stg -> prd deployment values via the same base package
* limit deployment options to:
  - be secure by default / allow for additional security restrictions
  - standardize access to the cloud env / how we intended interaction to EKS
  - sufficiently meet access controls (NIST 800-53), network controls and STIG requirements

## Decision

* The bastion module will:
  - inform how users can/are expected to interact with the environment
  - standardized access for the environment in an approved way that follows a similar pattern for cloud, air gap & on prem
  - establish a common pattern for users to interact with EKS / AWS managed services
* Customizable terraform root module (see complete example) will:
  - enable zarf to be the highly opinionated wrapper / version controlled mechanism
  - be extensible for different mission hero use cases / environments
* Sops module will:
  - create a common pattern for handling secrets & leverage a managed service via IAM roles for key rotations
  - assume flux or zarf will handle decription of values via the provided roles
* AWS Private Link will:
  - be enabled by the VPC and used by all resources
  - be enforced via IAM policy conditions to ensure that services are only accessible from within a VPC



## Consequences

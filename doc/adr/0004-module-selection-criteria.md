# 4. Selection Criteria for Upstream Terraform Modules

Date: 2023-05-04 (Effective 2023-01-02)

## Status

Accepted

## Context

This project was started to provide a highly opinionated secure and declarative infrastructure baseline that supports a Big Bang deployment in AWS. Below is a list of modules as of the first tag cut in this repository and how they primarily function.

* bastion
  - highly opinionated EC2 terraform module that informs how users can/are expected to interact with the environment
  - fully built / maintained by this project
* eks
  - opinionated wrapper of EKS Blueprints module (maintained by AWS Solution Architects)
* rds
  - opinionated wrapper of terraform-aws-rds module
  - supports big bang add-ons that need a managed service database
* s3-irsa
  - opinionated wrapper of terraform-aws-modules/s3-bucket
  - adds iam / kms AWS resources to enable irsa but depends on k8s configuration (svc account) to be handle by GitOps
* sops
  - highly opinionated iam / kms module that allows encryption / decryption of GitOps secrets via the bastion & flux in eks
  - adds iam / kms AWS resources to enable irsa but depends on k8s configuration (svc account) to be handle by GitOps
  - fully built / maintained by this project
* tfstate-backend
  - opinionated wrapper of terraform-aws-modules/s3-bucket
  - adds dynamodb / kms resources to enable secure tf state backend
* vpc
  - opinionated wrapper of terraform-aws-modules/vpc module
  - adds security group for VPC endpoints

As we start moving more toward treating our Terraform infrastructure code as a product, there is a need to capture previous decisions for module selection in order to enhance the process going forward. Below is a list of modules as of the first tag cut in this repository along with guiding principles that were taken into account for the initial selection:

* License
* Upstream had Active Community Support / Engagement
* Upstream was Well Maintained / Managed
* Upstream was Extensible (it can do what need)
* Simple design / didn't introduce additional complexity
* Upstream was testing (important for highly complex modules because we were doing it manually at the time)
* Ease to maintain ourself

## Decision

Below is a list of the original modules and why those early decisions were made.

* bastion (no upstream module selected)
  - We looked at the CloudPosse ec2-bastion-server and terraform-aws-ec2-instance but ultimately decided to completely "own" this for the following reasons.
    - The CloudPosse module hadn't been updated since mid-2021 and added complexity with the additional upstream opinionation (we were already VERY opinionated on this module)
    - We would have had to refactor to leverage the upstream terraform-aws-ec2-instance module and already had a ton of resources that were outside of it, so we decided at the time that the juice was worth the squeeze.
* eks (eks blueprints upstream)
  - We looked at several upstream modules and, because of the complexity, testing / upstream support was important. We ultimately chose EKS Blueprints because it was VERY active, well maintained (by AWS Solutions Architects) and tested.
* rds (terraform-aws-rds module upstream)
  - opinionated wrapper of terraform-aws-rds module
  - supports big bang add-ons that need a managed service database
* s3-irsa (terraform-aws-modules/s3-bucket)
  - opinionated wrapper of terraform-aws-modules/s3-bucket
  - adds iam / kms AWS resources to enable irsa but depends on k8s configuration (svc account) to be handle by GitOps
* sops (no upstream module selected)
  - this decision was made because it was simple, easy to maintain and there weren't any upstream options.
* tfstate-backend (terraform-aws-modules/s3-bucket)
  - We looked at the CloudPosse tfstate-backend module but it hadn't been updated since Nov 2021 and added complexity with the additional upstream opinionation.
  - this decision was made because it was simple and easy to maintain.
* vpc (terraform-aws-modules/vpc upstream)
  - the vpc submodule in EKS blueprints wasn't easily extensible for our use case and blueprints was simply opinionating the upstream module that we selected.
  - we chose this upstream modules because it was simple and well used in many places.

## Consequences

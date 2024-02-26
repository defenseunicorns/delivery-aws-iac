# Infrastructure-as-Code

This repository is used as an example project for the upstream UDS-IaC projects, as well as for integration testing those upstream modules when they have updates. When any of the upstream IaC modules receive a new release Renovate will open a PR and trigger a pipeline in this repository that performs integration and E2E tests.

## Getting Started

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information on how to contribute to this repository.

## Upstream Modules

Details of the UDS-IaC modules tested by this repository can be found in each of the upstream repositories:

- [VPC Module](https://github.com/defenseunicorns/terraform-aws-vpc)
- [RDS Module](https://github.com/defenseunicorns/terraform-aws-rds)
- [EKS Module](https://github.com/defenseunicorns/terraform-aws-eks)
- [Bastion Module](https://github.com/defenseunicorns/terraform-aws-bastion)
- [Lambda Module](https://github.com/defenseunicorns/terraform-aws-lambda)

## Supported Integrations

### EKS

See the `cluster_version` variable in [variables.tf](examples/complete/variables.tf) for the list of supported EKS versions.

### Defense Unicorns Big Bang Distribution (DUBBD)

We intend for the latest version of DUBBD to be deployable on top of the infrastructure created by [the example root module](examples/complete), but we aren't yet testing this in our automated tests. If you encounter any issues with this, please [open an issue](https://github.com/defenseunicorns/delivery-aws-iac/issues/new/choose).

# Infrastructure-as-Code

This repository is used as an example project for the upstream UDS-IaC projects, as well as for integration testing those upstream modules when they have updates. When any of the upstream IaC modules receive a new release Renovate will open a PR and trigger a pipeline in this repository that performs integration and E2E tests.

This repository references a collection of Terraform modules designed to help you quickly and easily build robust, scalable infrastructure. Each module represents a best-practice, opinionated design for a specific piece of infrastructure, such as an EKS cluster, load balancer, database or S3 bucket needed to satisfy [Big Bang](https://docs-bigbang.dso.mil/) dependencies. At the example level, both an option for Self-Managed and Managed node groups are included. Depending on which type of node group you are using be sure to run terraform from inside the corresponding example. By using these modules, you can take advantage of the experience and insights of the module authors, who have spent countless hours testing and refining the designs to ensure their reliability and efficiency. In addition, the versioning of these modules allows you to track and manage changes to your infrastructure with confidence. Whether you are a seasoned infrastructure engineer or new to the field, these modules are an invaluable tool for building and maintaining your infrastructure.

## Getting Started

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information on how to contribute to this repository.

## Upstream Modules

Details of the UDS-IaC modules tested by this repository can be found in each of the upstream repositories:

- [VPC Module](https://github.com/defenseunicorns/terraform-aws-uds-vpc)
- [RDS Module](https://github.com/defenseunicorns/terraform-aws-uds-rds)
- [EKS Module](https://github.com/defenseunicorns/terraform-aws-uds-eks)
- [Bastion Module](https://github.com/defenseunicorns/terraform-aws-uds-bastion)

## Supported Integrations

### EKS
See the `cluster_version` variable in [variables.tf](examples/complete/variables.tf) for the list of supported EKS versions.

### Defense Unicorns Big Bang Distribution (DUBBD)
We intend for the latest version of DUBBD to be deployable on top of the infrastructure created by [the example root module](examples/complete), but we aren't yet testing this in our automated tests. If you encounter any issues with this, please [open an issue](https://github.com/defenseunicorns/delivery-aws-iac/issues/new/choose).

### Zarf
Our automated tests use the latest version of Zarf. Zarf versions previous to v0.25.0 are not supported.

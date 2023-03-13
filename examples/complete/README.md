# Complete Example: EKS Cluster Deployment with new VPC & Big Bang Dependencies

This example deploys:

- A VPC with:
  - 3 public subnets with internet gateway
  - 3 private subnets with NAT gateway
- An EKS cluster with worker node group(s)
- A Bastion host in one of the private subnets
- Big Bang dependencies:
  - KMS key and IAM roles for SOPS and IRSA
  - S3 bucket for Loki
  - RDS database for Keycloak

> This example has 2 modes: "insecure" and "secure". Insecure mode uses managed nodegroups, default instance tenancy, and enables the public endpoint on the EKS cluster. Secure mode uses self-managed nodegroups, dedicated instance tenancy, and disables the public endpoint on the EKS cluster. The method of choosing which mode to use is by using either `fixtures.insecure.tfvars` or `fixtures.secure.tfvars` as an overlay on top of `fixtures.common.tfvars`.

> NOTE: Secure mode doesn't exist yet. Stay tuned or use the `complete-self-managed-nodegroup` example. Once this example has secure mode available the `complete-self-managed-nodegroup` example will be deprecated/deleted.

## Configure

- If you want access to the cluster, update the `aws_admin_usernames` variable in `fixtures.common.tfvars` to include your IAM username.
  > Easily retrieve your IAM username with `aws iam get-user | jq '.[]' | jq -r '.UserName'`
- Feel free to change other variables to suit your needs.

## Deploy/Destroy

See the [examples README](../README.md) for instructions on how to deploy/destroy this example. The make targets for this example are either `test-complete-insecure` or `test-complete-secure`.

## Connect

### Insecure mode

In insecure mode, the EKS cluster has a public endpoint. You can get the kubeconfig you need to connect to the cluster with the following command:

```shell
aws eks update-kubeconfig --region <RegionYouUsed> --name <ClusterName> --kubeconfig <PathToKubeconfigYouWantToModify> --alias <AliasForTheCluster>
```
> Use `aws eks list-clusters --region <RegionYouUsed>` to get the name of the cluster.

### Secure mode

Coming soon

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

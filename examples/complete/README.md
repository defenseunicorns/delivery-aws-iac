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
- Password rotation lambda module.
  - This module can be enabled or disabled. Enabled by default for E2E testing.
  - you can also modify the crob job schedule by changing the cron_schedule_password_rotation variable
  - if enabled ensure you pass instance ids as seen in examples/complete/main.tf `instance_ids = [module.bastion.instance_id]` and users to the function via fixtures.common.tfvars for example.
  - You also have the option of enabling slack notifications for the password rotation status by setting the variables slack_notification_enabled and slack_webhook_url
  - Note that this function deploys resources outside of terraform. Secrets and Parameter store resources are created by the function and need to be deleted manually. If slack notifications are enabled you will need to create a slack webhook url to put into the variable.

> This example has 2 modes: "insecure"(commercial) and "secure"(govcloud). Insecure mode uses managed nodegroups, default instance tenancy, and enables the public endpoint on the EKS cluster. Secure mode uses self-managed nodegroups, dedicated instance tenancy, and disables the public endpoint on the EKS cluster. The method of choosing which mode to use is by using either `fixtures.insecure.tfvars` or `fixtures.secure.tfvars` as an overlay on top of `fixtures.common.tfvars`.

## Deploy/Destroy

See the [examples README](../README.md) for instructions on how to deploy/destroy this example. The make targets for this example are either `test-ci-complete-insecure` or `test-release-complete-secure`.

## Connect

### Insecure mode

In insecure mode, the EKS cluster has a public endpoint. You can get the kubeconfig you need to connect to the cluster with the following command:

```shell
aws eks update-kubeconfig --region <RegionYouUsed> --name <ClusterName> --kubeconfig <PathToKubeconfigYouWantToModify> --alias <AliasForTheCluster>
```
> Use `aws eks list-clusters --region <RegionYouUsed>` to get the name of the cluster.

### Secure mode

In secure mode, the EKS cluster does not have a public endpoint. To connect to it, you'll need to tunnel through the bastion host. We use `sshuttle` to do this.

For convenience, we have set up a Make target called `bastion-connect`. Running the target will run a Docker container with `sshuttle` already running and the KUBECONFIG already configured and drop you into a bash shell inside the container.

```shell
aws-vault exec <your-profile> -- make bastion-connect

SShuttle is running and KUBECONFIG has been set. Try running kubectl get nodes.
[root@f72f0495c0cd complete]$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-200-36-117.us-east-2.compute.internal   Ready    <none>   22h   v1.23.16-eks-48e63af
ip-10-200-41-153.us-east-2.compute.internal   Ready    <none>   22h   v1.23.16-eks-48e63af
ip-10-200-48-31.us-east-2.compute.internal    Ready    <none>   22h   v1.23.16-eks-48e63af
```

To do this manually, you're going to want to run:

> NOTE: This is not really recommended. Better to use the make target / docker container. If the container doesn't have a tool you need, open an issue [here](https://github.com/defenseunicorns/build-harness) and we'll get it added.

```shell
# Switch to the examples/complete directory
cd examples/complete

# Init Terraform
terraform init

# Set up the AWS environment. This will drop you into a new shell with the env vars you need.
aws-vault exec <your-profile>

# Make sure you have the env vars you need
env | grep AWS
AWS_VAULT=<redacted>
AWS_DEFAULT_REGION=<redacted>
AWS_REGION=<redacted>
AWS_ACCESS_KEY_ID=<redacted>
AWS_SECRET_ACCESS_KEY=<redacted>
AWS_SESSION_TOKEN=<redacted>
AWS_SECURITY_TOKEN=<redacted>
AWS_SESSION_EXPIRATION=<redacted>

# Run sshuttle in the background. Don't forget to kill the background process when you are done. Use 'ps' to get the PID, then use 'kill -15 <PID>' to kill it.
# There's a ton of stuff here. Here's the breakdown:
# sshpass: pass the bastion's SSH password noninteractively
# -D: Run sshuttle in daemon (background) mode. Don't use '-D' if you'd rather run it in the foreground in a separate terminal window.
# -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null: Don't check the bastion's host key
# -o ProxyCommand="...": Tell SSH to use AWS SSM
sshuttle -D -e 'sshpass -p "my-password" ssh -q -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="aws ssm --region $(terraform output -raw bastion_region) start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"' --dns --disable-ipv6 -vr ec2-user@$(terraform output -raw bastion_instance_id) $(terraform output -raw vpc_cidr)

# Set up the KUBECONFIG
aws eks --region $(terraform output -raw bastion_region) update-kubeconfig --name $(terraform output -raw eks_cluster_name)

# Test it out
kubectl get nodes
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | 2.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.62.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.5.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 2.4.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.62.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | git::https://github.com/defenseunicorns/terraform-aws-bastion.git | v0.0.11 |
| <a name="module_ebs_kms_key"></a> [ebs\_kms\_key](#module\_ebs\_kms\_key) | terraform-aws-modules/kms/aws | ~> 2.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | git::https://github.com/defenseunicorns/terraform-aws-eks.git | v0.0.12 |
| <a name="module_key_pair"></a> [key\_pair](#module\_key\_pair) | terraform-aws-modules/key-pair/aws | ~> 2.0 |
| <a name="module_password_lambda"></a> [password\_lambda](#module\_password\_lambda) | git::https://github.com/defenseunicorns/terraform-aws-lambda.git//modules/password-rotation | v0.0.3 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://github.com/defenseunicorns/terraform-aws-vpc.git | v0.1.5 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.access_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.access_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.access_log_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.access_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.access_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.access_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sqs_queue.access_log_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [kubernetes_job_v1.test_write](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job_v1) | resource |
| [kubernetes_namespace.iac](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim_v1.test_claim](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [random_id.default](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_ami.amazonlinux2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.eks_default_bottlerocket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_expire_days"></a> [access\_log\_expire\_days](#input\_access\_log\_expire\_days) | Number of days to wait before deleting access logs | `number` | `30` | no |
| <a name="input_aws_admin_usernames"></a> [aws\_admin\_usernames](#input\_aws\_admin\_usernames) | A list of one or more AWS usernames with authorized access to KMS and EKS resources, will automatically add the user running the terraform as an admin | `list(string)` | `[]` | no |
| <a name="input_aws_efs_csi_driver"></a> [aws\_efs\_csi\_driver](#input\_aws\_efs\_csi\_driver) | AWS EFS CSI Driver helm chart config | `any` | `{}` | no |
| <a name="input_aws_node_termination_handler"></a> [aws\_node\_termination\_handler](#input\_aws\_node\_termination\_handler) | AWS Node Termination Handler config for aws-ia/eks-blueprints-addon/aws | `any` | `{}` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | value for the instance type of the EKS worker nodes | `string` | `"m5.xlarge"` | no |
| <a name="input_bastion_ssh_password"></a> [bastion\_ssh\_password](#input\_bastion\_ssh\_password) | The SSH password to use for the bastion if SSM authentication is used | `string` | `"my-password"` | no |
| <a name="input_bastion_ssh_user"></a> [bastion\_ssh\_user](#input\_bastion\_ssh\_user) | The SSH user to use for the bastion | `string` | `"ec2-user"` | no |
| <a name="input_bastion_tenancy"></a> [bastion\_tenancy](#input\_bastion\_tenancy) | The tenancy of the bastion | `string` | `"default"` | no |
| <a name="input_cluster_addons"></a> [cluster\_addons](#input\_cluster\_addons) | Nested of eks native add-ons and their associated parameters.<br>See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_add-on for supported values.<br>See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/complete/main.tf#L44-L60 for upstream example.<br><br>to see available eks marketplace addons available for your cluster's version run:<br>aws eks describe-addon-versions --kubernetes-version $k8s\_cluster\_version --query 'addons[].{MarketplaceProductUrl: marketplaceInformation.productUrl, Name: addonName, Owner: owner Publisher: publisher, Type: type}' --output table | `any` | `{}` | no |
| <a name="input_cluster_autoscaler"></a> [cluster\_autoscaler](#input\_cluster\_autoscaler) | Cluster Autoscaler Helm Chart config | `any` | `{}` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable private access to the EKS cluster | `bool` | `false` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for EKS cluster | `string` | `"1.27"` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap` | `bool` | `false` | no |
| <a name="input_cron_schedule_password_rotation"></a> [cron\_schedule\_password\_rotation](#input\_cron\_schedule\_password\_rotation) | Schedule for password change function to run on | `string` | `"cron(0 0 1 * ? *)"` | no |
| <a name="input_eks_use_mfa"></a> [eks\_use\_mfa](#input\_eks\_use\_mfa) | Use MFA for auth\_eks\_role | `bool` | n/a | yes |
| <a name="input_eks_worker_tenancy"></a> [eks\_worker\_tenancy](#input\_eks\_worker\_tenancy) | The tenancy of the EKS worker nodes | `string` | `"default"` | no |
| <a name="input_enable_amazon_eks_aws_ebs_csi_driver"></a> [enable\_amazon\_eks\_aws\_ebs\_csi\_driver](#input\_enable\_amazon\_eks\_aws\_ebs\_csi\_driver) | Enable EKS Managed AWS EBS CSI Driver add-on | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_aws_efs_csi_driver"></a> [enable\_amazon\_eks\_aws\_efs\_csi\_driver](#input\_enable\_amazon\_eks\_aws\_efs\_csi\_driver) | Enable EFS CSI add-on | `bool` | `false` | no |
| <a name="input_enable_aws_node_termination_handler"></a> [enable\_aws\_node\_termination\_handler](#input\_enable\_aws\_node\_termination\_handler) | Enable AWS Node Termination Handler add-on | `bool` | `false` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | If true, a bastion will be created | `bool` | `true` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable Cluster autoscaler add-on | `bool` | `false` | no |
| <a name="input_enable_eks_managed_nodegroups"></a> [enable\_eks\_managed\_nodegroups](#input\_enable\_eks\_managed\_nodegroups) | Enable managed node groups | `bool` | n/a | yes |
| <a name="input_enable_gp3_default_storage_class"></a> [enable\_gp3\_default\_storage\_class](#input\_enable\_gp3\_default\_storage\_class) | Enable gp3 as default storage class | `bool` | `false` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Enable metrics server add-on | `bool` | `false` | no |
| <a name="input_enable_self_managed_nodegroups"></a> [enable\_self\_managed\_nodegroups](#input\_enable\_self\_managed\_nodegroups) | Enable self managed node groups | `bool` | n/a | yes |
| <a name="input_enable_sqs_events_on_access_log_access"></a> [enable\_sqs\_events\_on\_access\_log\_access](#input\_enable\_sqs\_events\_on\_access\_log\_access) | If true, generates an SQS event whenever on object is created in the Access Log bucket, which happens whenever a server access log is generated by any entity. This will potentially generate a lot of events, so use with caution. | `bool` | `false` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for IAM roles | `string` | `null` | no |
| <a name="input_keycloak_enabled"></a> [keycloak\_enabled](#input\_keycloak\_enabled) | Enable Keycloak dedicated nodegroup | `bool` | `false` | no |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | Waiting period for scheduled KMS Key deletion. Can be 7-30 days. | `number` | `7` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Determines whether to manage the aws-auth configmap | `bool` | `false` | no |
| <a name="input_metrics_server"></a> [metrics\_server](#input\_metrics\_server) | Metrics Server config for aws-ia/eks-blueprints-addon/aws | `any` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The prefix to use when naming all resources | `string` | `"ex-complete"` | no |
| <a name="input_num_azs"></a> [num\_azs](#input\_num\_azs) | The number of AZs to use | `number` | `3` | no |
| <a name="input_reclaim_policy"></a> [reclaim\_policy](#input\_reclaim\_policy) | Reclaim policy for EFS storage class, valid options are Delete and Retain | `string` | `"Delete"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | A list of secondary CIDR blocks for the VPC | `list(string)` | `[]` | no |
| <a name="input_slack_notification_enabled"></a> [slack\_notification\_enabled](#input\_slack\_notification\_enabled) | enable slack notifications for password rotation function. If enabled a slack webhook url will also need to be provided for this to work | `bool` | `false` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | value | `string` | `null` | no |
| <a name="input_storageclass_reclaim_policy"></a> [storageclass\_reclaim\_policy](#input\_storageclass\_reclaim\_policy) | Reclaim policy for gp3 storage class, valid options are Delete and Retain | `string` | `"Delete"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | This needs to be a list of users that will be on your ec2 instances that need password changes. | `list(string)` | `[]` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_zarf_version"></a> [zarf\_version](#input\_zarf\_version) | The version of Zarf to use | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The ID of the bastion host |
| <a name="output_bastion_private_dns"></a> [bastion\_private\_dns](#output\_bastion\_private\_dns) | The private DNS address of the bastion host |
| <a name="output_bastion_region"></a> [bastion\_region](#output\_bastion\_region) | The region that the bastion host was deployed to |
| <a name="output_efs_storageclass_name"></a> [efs\_storageclass\_name](#output\_efs\_storageclass\_name) | The name of the EFS storageclass that was created (if var.enable\_amazon\_eks\_aws\_efs\_csi\_driver was set to true) |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | The name of the EKS cluster |
| <a name="output_lambda_password_function_arn"></a> [lambda\_password\_function\_arn](#output\_lambda\_password\_function\_arn) | Arn for lambda password function |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR block of the VPC |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

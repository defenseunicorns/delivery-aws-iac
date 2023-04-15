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

> NOTE: This is not really recommended. Better to use the make target / docker container. If the container doesn't have a tool you need, open an issue [here](https://github.com/defenseunicorns/not-a-build-harness) and we'll get it added.

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.5.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.8.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ../../modules/eks | n/a |
| <a name="module_flux_sops"></a> [flux\_sops](#module\_flux\_sops) | ../../modules/sops | n/a |
| <a name="module_loki_s3_bucket"></a> [loki\_s3\_bucket](#module\_loki\_s3\_bucket) | ../../modules/s3-irsa | n/a |
| <a name="module_rds_postgres_keycloak"></a> [rds\_postgres\_keycloak](#module\_rds\_postgres\_keycloak) | ../../modules/rds | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_id.default](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_ami.amazonlinux2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amazon_eks_aws_ebs_csi_driver_config"></a> [amazon\_eks\_aws\_ebs\_csi\_driver\_config](#input\_amazon\_eks\_aws\_ebs\_csi\_driver\_config) | configMap for AWS EBS CSI Driver add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_coredns_config"></a> [amazon\_eks\_coredns\_config](#input\_amazon\_eks\_coredns\_config) | Configuration for Amazon CoreDNS EKS add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_kube_proxy_config"></a> [amazon\_eks\_kube\_proxy\_config](#input\_amazon\_eks\_kube\_proxy\_config) | ConfigMap for Amazon EKS Kube-Proxy add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_vpc_cni"></a> [amazon\_eks\_vpc\_cni](#input\_amazon\_eks\_vpc\_cni) | The VPC CNI add-on configuration.<br>enable - (Optional) Whether to enable the add-on. Defaults to false.<br>before\_compute - (Optional) Whether to create the add-on before the compute resources. Defaults to true.<br>most\_recent - (Optional) Whether to use the most recent version of the add-on. Defaults to true.<br>resolve\_conflicts - (Optional) How to resolve parameter value conflicts between the add-on and the cluster. Defaults to OVERWRITE. Valid values: OVERWRITE, NONE, PRESERVE.<br>configuration\_values - (Optional) A map of configuration values for the add-on. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_add-on for supported values.<br>preserve - (Optional) Whether to preserve the add-on's objects when the add-on is deleted. Defaults to false. | <pre>object({<br>    enable               = bool<br>    before_compute       = bool<br>    most_recent          = bool<br>    resolve_conflicts    = string<br>    configuration_values = map(any) # hcl format later to be json encoded<br>    preserve             = bool<br>  })</pre> | <pre>{<br>  "before_compute": true,<br>  "configuration_values": {<br>    "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG": "true",<br>    "ENABLE_PREFIX_DELEGATION": "true",<br>    "ENI_CONFIG_LABEL_DEF": "topology.kubernetes.io/zone",<br>    "WARM_PREFIX_TARGET": "1"<br>  },<br>  "enable": false,<br>  "most_recent": true,<br>  "preserve": false,<br>  "resolve_conflicts": "OVERWRITE"<br>}</pre> | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign a public IP to the bastion | `bool` | `false` | no |
| <a name="input_aws_admin_usernames"></a> [aws\_admin\_usernames](#input\_aws\_admin\_usernames) | A list of one or more AWS usernames with authorized access to KMS and EKS resources, will automatically add the user running the terraform as an admin | `list(string)` | `[]` | no |
| <a name="input_aws_node_termination_handler_helm_config"></a> [aws\_node\_termination\_handler\_helm\_config](#input\_aws\_node\_termination\_handler\_helm\_config) | AWS Node Termination Handler Helm Chart config | `any` | `{}` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | value for the instance type of the EKS worker nodes | `string` | `"m5.xlarge"` | no |
| <a name="input_bastion_ssh_password"></a> [bastion\_ssh\_password](#input\_bastion\_ssh\_password) | The SSH password to use for the bastion if SSM authentication is used | `string` | `"my-password"` | no |
| <a name="input_bastion_ssh_user"></a> [bastion\_ssh\_user](#input\_bastion\_ssh\_user) | The SSH user to use for the bastion | `string` | `"ec2-user"` | no |
| <a name="input_bastion_tenancy"></a> [bastion\_tenancy](#input\_bastion\_tenancy) | The tenancy of the bastion | `string` | `"default"` | no |
| <a name="input_cluster_autoscaler_helm_config"></a> [cluster\_autoscaler\_helm\_config](#input\_cluster\_autoscaler\_helm\_config) | Cluster Autoscaler Helm Chart config | `any` | `{}` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable private access to the EKS cluster | `bool` | `false` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for EKS cluster | `string` | `"1.23"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Whether to create a database subnet group | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Whether to create a database subnet route table | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | A map of default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_worker_tenancy"></a> [eks\_worker\_tenancy](#input\_eks\_worker\_tenancy) | The tenancy of the EKS worker nodes | `string` | `"default"` | no |
| <a name="input_enable_amazon_eks_aws_ebs_csi_driver"></a> [enable\_amazon\_eks\_aws\_ebs\_csi\_driver](#input\_enable\_amazon\_eks\_aws\_ebs\_csi\_driver) | Enable EKS Managed AWS EBS CSI Driver add-on; enable\_amazon\_eks\_aws\_ebs\_csi\_driver and enable\_self\_managed\_aws\_ebs\_csi\_driver are mutually exclusive | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_coredns"></a> [enable\_amazon\_eks\_coredns](#input\_enable\_amazon\_eks\_coredns) | Enable Amazon EKS CoreDNS add-on | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_kube_proxy"></a> [enable\_amazon\_eks\_kube\_proxy](#input\_enable\_amazon\_eks\_kube\_proxy) | Enable Kube Proxy add-on | `bool` | `false` | no |
| <a name="input_enable_aws_node_termination_handler"></a> [enable\_aws\_node\_termination\_handler](#input\_enable\_aws\_node\_termination\_handler) | Enable AWS Node Termination Handler add-on | `bool` | `false` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable Cluster autoscaler add-on | `bool` | `false` | no |
| <a name="input_enable_eks_managed_nodegroups"></a> [enable\_eks\_managed\_nodegroups](#input\_enable\_eks\_managed\_nodegroups) | Enable managed node groups | `bool` | n/a | yes |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Enable metrics server add-on | `bool` | `false` | no |
| <a name="input_enable_self_managed_nodegroups"></a> [enable\_self\_managed\_nodegroups](#input\_enable\_self\_managed\_nodegroups) | Enable self managed node groups | `bool` | n/a | yes |
| <a name="input_kc_db_allocated_storage"></a> [kc\_db\_allocated\_storage](#input\_kc\_db\_allocated\_storage) | The database allocated storage to use for Keycloak | `number` | n/a | yes |
| <a name="input_kc_db_engine_version"></a> [kc\_db\_engine\_version](#input\_kc\_db\_engine\_version) | The database engine to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_family"></a> [kc\_db\_family](#input\_kc\_db\_family) | The database family to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_instance_class"></a> [kc\_db\_instance\_class](#input\_kc\_db\_instance\_class) | The database instance class to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_major_engine_version"></a> [kc\_db\_major\_engine\_version](#input\_kc\_db\_major\_engine\_version) | The database major engine version to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_max_allocated_storage"></a> [kc\_db\_max\_allocated\_storage](#input\_kc\_db\_max\_allocated\_storage) | The database allocated storage to use for Keycloak | `number` | n/a | yes |
| <a name="input_keycloak_db_password"></a> [keycloak\_db\_password](#input\_keycloak\_db\_password) | The password to use for the Keycloak database | `string` | `"my-password"` | no |
| <a name="input_keycloak_enabled"></a> [keycloak\_enabled](#input\_keycloak\_enabled) | Whether to enable Keycloak | `bool` | `false` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Determines whether to manage the aws-auth configmap | `bool` | `false` | no |
| <a name="input_metrics_server_helm_config"></a> [metrics\_server\_helm\_config](#input\_metrics\_server\_helm\_config) | Metrics Server Helm Chart config | `any` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The prefix to use when naming all resources | `string` | `"ex-complete"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_region2"></a> [region2](#input\_region2) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | A list of secondary CIDR blocks for the VPC | `list(string)` | `[]` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_zarf_version"></a> [zarf\_version](#input\_zarf\_version) | The version of Zarf to use | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The ID of the bastion host |
| <a name="output_bastion_private_dns"></a> [bastion\_private\_dns](#output\_bastion\_private\_dns) | The private DNS address of the bastion host |
| <a name="output_bastion_private_key"></a> [bastion\_private\_key](#output\_bastion\_private\_key) | The private key for the bastion host |
| <a name="output_bastion_region"></a> [bastion\_region](#output\_bastion\_region) | The region that the bastion host was deployed to |
| <a name="output_dynamodb_name"></a> [dynamodb\_name](#output\_dynamodb\_name) | Name of DynmoDB table |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | The name of the EKS cluster |
| <a name="output_keycloak_db_instance_endpoint"></a> [keycloak\_db\_instance\_endpoint](#output\_keycloak\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_keycloak_db_instance_name"></a> [keycloak\_db\_instance\_name](#output\_keycloak\_db\_instance\_name) | The database name |
| <a name="output_keycloak_db_instance_port"></a> [keycloak\_db\_instance\_port](#output\_keycloak\_db\_instance\_port) | The database port |
| <a name="output_keycloak_db_instance_username"></a> [keycloak\_db\_instance\_username](#output\_keycloak\_db\_instance\_username) | The master username for the database |
| <a name="output_loki_s3_bucket"></a> [loki\_s3\_bucket](#output\_loki\_s3\_bucket) | Loki S3 Bucket Name |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR block of the VPC |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

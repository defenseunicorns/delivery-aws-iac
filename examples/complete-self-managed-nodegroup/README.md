# EKS Cluster Deployment with new VPC & Big Bang Dependencies

This example deploys the following Basic Self-Managed EKS Cluster with VPC

- Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
- Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- Creates EKS Cluster Control plane with one managed node group
- Creates a Bastion host in a private subnet
- Creates dependencies needed for BigBang

---
**Table of contents:**
- [EKS Cluster Deployment with new VPC \& Big Bang Dependencies](#eks-cluster-deployment-with-new-vpc--big-bang-dependencies)
  - [How to Deploy](#how-to-deploy)
    - [Prerequisites](#prerequisites)
    - [Deployment Steps](#deployment-steps)
      - [Step 1: Preparation](#step-1-preparation)
      - [Step 2: Modify terraform.tfvars (located in tmp directory) with desired values](#step-2-modify-terraformtfvars-located-in-tmp-directory-with-desired-values)
      - [Step 3: Terraform Init \& State](#step-3-terraform-init--state)
        - [local](#local)
        - [remote](#remote)
      - [Step 4: Provision VPC and Bastion](#step-4-provision-vpc-and-bastion)
      - [Step 5: (Required if EKS Public Access set to False) Connect to the Bastion using SSHuttle and Provision the remaining Infrastucture](#step-5-required-if-eks-public-access-set-to-false-connect-to-the-bastion-using-sshuttle-and-provision-the-remaining-infrastucture)
    - [Configure `kubectl` and test cluster](#configure-kubectl-and-test-cluster)
      - [Step 6: Run the `aws eks update-kubeconfig` command](#step-6-run-the-aws-eks-update-kubeconfig-command)
      - [Step 7: List all the worker nodes by running the command below](#step-7-list-all-the-worker-nodes-by-running-the-command-below)
      - [Step 8: List all the pods running in `kube-system` namespace](#step-8-list-all-the-pods-running-in-kube-system-namespace)
  - [Cleanup](#cleanup)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

---

## How to Deploy

### Prerequisites

Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run Terraform Plan and Apply

1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [Kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [Helm](https://helm.sh/docs/intro/install/)
4. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
5. [SSHuttle](https://github.com/sshuttle/sshuttle)

Ensure that your AWS credentials are configured. This can be done by running `aws configure`

### Deployment Steps

#### Step 1: Preparation

```sh
git clone https://github.com/defenseunicorns/iac.git
cd ./iac/examples/complete-self-managed-nodegroup
cp terraform.tfvars.example terraform.tfvars
```

#### Step 2: Modify terraform.tfvars (located in tmp directory) with desired values

AWS usernames must be changed to match actual usernames `aws iam get-user | jq '.[]' | jq -r '.UserName'`

#### Step 3: Terraform Init & State

Use remote or local state for terraform

##### local

Initialize a working directory with configuration files and create local terraform state file

```sh
terraform init
```

##### remote

Alternatively, you can provision an S3 backend prior to this step using the tf-state-backend example and init via the following:

```sh
#from the ./iac/examples/complete-self-managed-nodegroup directory
pushd ../tf-state-backend

terraform apply
export BUCKET_ID=`(terraform output -raw tfstate_bucket_id)`
export DYNAMODB_TABLE_NAME=`(terraform output -raw tfstate_dynamodb_table_name)`

popd

export AWS_DEFAULT_REGION=$(grep 'region' terraform.tfvars | grep -v 'region2' |cut -d'=' -f2 | cut -d'#' -f1 | tr -d '[:space:]' | sed 's/"//g')

#make backend file
cp backend.tf.example backend.tf

#init and copy state if it exists
terraform init -force-copy -backend-config="bucket=$BUCKET_ID" \
  -backend-config="key=complete-self-managed-nodegroup/terraform.tfstate" \
  -backend-config="dynamodb_table=$DYNAMODB_TABLE_NAME" \
  -backend-config="region=$AWS_DEFAULT_REGION"
```

#### Step 4: Provision VPC and Bastion

```sh
# plan deployment and verify desired outcome
terraform plan -target=module.vpc -target=module.bastion

# type yes to confirm or utilize the '-auto-approve' flag
terraform apply -target=module.vpc -target=module.bastion
```

#### Step 5: (Required if EKS Public Access set to False) Connect to the Bastion using SSHuttle and Provision the remaining Infrastucture

Add the following to your ~/.ssh/config to connect to the Bastion via AWS SSM (create config file if it does not exist)

```sh
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

Test SSH connection to the Bastion

```sh
# grab bastion instance id from terraform
export BASTION_INSTANCE_ID=`(terraform output -raw bastion_instance_id)`
# replace "my-password" with the variable set (if changed from the default)
expect -c 'spawn ssh ec2-user@$BASTION_INSTANCE_ID ; expect "assword:"; send "my-password\r"; interact'
```

In a new terminal, open an sshuttle tunnel to the bastion

```sh
# subnet below is the CIDR block from your tfvars file
sshuttle --dns -vr ec2-user@$BASTION_INSTANCE_ID 10.200.0.0/16
```

Navigate back to the terminal in the `complete-self-managed-nodegroup` directory and Provision the EKS Cluster

```sh
terraform apply -var-file
# type yes to confirm or utilize the ```-auto-approve``` flag in the above command
```

### Configure `kubectl` and test cluster

Note: In this example we are using a private EKS Cluster endpoint for the control plane. You must ensure the sshuttle is running to the bastion to utilize `kubectl`

EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster.
This following command used to update the `kubeconfig` in your local machine where you run kubectl commands to interact with your EKS Cluster.

#### Step 6: Run the `aws eks update-kubeconfig` command

`~/.kube/config` file gets updated with cluster details and certificate from the below command

```bash
CLUSTER_NAME=$(grep 'cluster_name' terraform.tfvars | cut -d'=' -f2 | tr -d '[:space:]' | sed 's/"//g')
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME
```

#### Step 7: List all the worker nodes by running the command below

    kubectl get nodes

#### Step 8: List all the pods running in `kube-system` namespace

    kubectl get pods -n kube-system

## Cleanup

To clean up your environment, destroy the Terraform modules in reverse order.

Destroy the Kubernetes Add-ons / EKS cluster first (requires sshuttle through bastion if EKS Public Access set to False)

```sh
terraform destroy -auto-approve -target=module.eks
```

Destroy all other resources

```sh
terraform destroy -auto-approve
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.9 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |

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
| [aws_ami.amazonlinux2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | The AWS account to deploy into | `string` | n/a | yes |
| <a name="input_amazon_eks_aws_ebs_csi_driver_config"></a> [amazon\_eks\_aws\_ebs\_csi\_driver\_config](#input\_amazon\_eks\_aws\_ebs\_csi\_driver\_config) | configMap for AWS EBS CSI Driver add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_coredns_config"></a> [amazon\_eks\_coredns\_config](#input\_amazon\_eks\_coredns\_config) | Configuration for Amazon CoreDNS EKS add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_kube_proxy_config"></a> [amazon\_eks\_kube\_proxy\_config](#input\_amazon\_eks\_kube\_proxy\_config) | ConfigMap for Amazon EKS Kube-Proxy add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_vpc_cni"></a> [amazon\_eks\_vpc\_cni](#input\_amazon\_eks\_vpc\_cni) | The VPC CNI add-on configuration.<br>enable - (Optional) Whether to enable the add-on. Defaults to false.<br>before\_compute - (Optional) Whether to create the add-on before the compute resources. Defaults to true.<br>most\_recent - (Optional) Whether to use the most recent version of the add-on. Defaults to true.<br>resolve\_conflicts - (Optional) How to resolve parameter value conflicts between the add-on and the cluster. Defaults to OVERWRITE. Valid values: OVERWRITE, NONE, PRESERVE.<br>configuration\_values - (Optional) A map of configuration values for the add-on. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon for supported values. | <pre>object({<br>    enable               = bool<br>    before_compute       = bool<br>    most_recent          = bool<br>    resolve_conflicts    = string<br>    configuration_values = map(any) # hcl format later to be json encoded<br>  })</pre> | <pre>{<br>  "before_compute": true,<br>  "configuration_values": {<br>    "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG": "true",<br>    "ENABLE_PREFIX_DELEGATION": "true",<br>    "ENI_CONFIG_LABEL_DEF": "topology.kubernetes.io/zone",<br>    "WARM_PREFIX_TARGET": "1"<br>  },<br>  "enable": false,<br>  "most_recent": true,<br>  "resolve_conflicts": "OVERWRITE"<br>}</pre> | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign a public IP to the bastion | `bool` | `false` | no |
| <a name="input_aws_admin_usernames"></a> [aws\_admin\_usernames](#input\_aws\_admin\_usernames) | A list of one or more AWS usernames with authorized access to KMS and EKS resources, will automatically add the user running the terraform as an admin | `list(string)` | `[]` | no |
| <a name="input_aws_node_termination_handler_helm_config"></a> [aws\_node\_termination\_handler\_helm\_config](#input\_aws\_node\_termination\_handler\_helm\_config) | AWS Node Termination Handler Helm Chart config | `any` | `{}` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use for deployment | `string` | n/a | yes |
| <a name="input_bastion_ami_id"></a> [bastion\_ami\_id](#input\_bastion\_ami\_id) | (Optional) The AMI ID to use for the bastion, will query the latest Amazon Linux 2 AMI if not provided | `string` | `""` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | value for the instance type of the EKS worker nodes | `string` | `"m5.xlarge"` | no |
| <a name="input_bastion_name"></a> [bastion\_name](#input\_bastion\_name) | The name to use for the bastion | `string` | `"my-bastion"` | no |
| <a name="input_bastion_ssh_password"></a> [bastion\_ssh\_password](#input\_bastion\_ssh\_password) | The SSH password to use for the bastion if SSM authentication is used | `string` | `"my-password"` | no |
| <a name="input_bastion_ssh_user"></a> [bastion\_ssh\_user](#input\_bastion\_ssh\_user) | The SSH user to use for the bastion | `string` | `"ec2-user"` | no |
| <a name="input_bastion_tenancy"></a> [bastion\_tenancy](#input\_bastion\_tenancy) | The tenancy of the bastion | `string` | `"default"` | no |
| <a name="input_cluster_autoscaler_helm_config"></a> [cluster\_autoscaler\_helm\_config](#input\_cluster\_autoscaler\_helm\_config) | Cluster Autoscaler Helm Chart config | `any` | `{}` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable private access to the EKS cluster | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to use for the EKS cluster | `string` | `"my-eks"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The Kubernetes version to use for the EKS cluster | `string` | `"1.23"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Whether to create a database subnet group | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Whether to create a database subnet route table | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | A map of default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_worker_tenancy"></a> [eks\_worker\_tenancy](#input\_eks\_worker\_tenancy) | The tenancy of the EKS worker nodes | `string` | `"default"` | no |
| <a name="input_enable_amazon_eks_aws_ebs_csi_driver"></a> [enable\_amazon\_eks\_aws\_ebs\_csi\_driver](#input\_enable\_amazon\_eks\_aws\_ebs\_csi\_driver) | Enable EKS Managed AWS EBS CSI Driver add-on; enable\_amazon\_eks\_aws\_ebs\_csi\_driver and enable\_self\_managed\_aws\_ebs\_csi\_driver are mutually exclusive | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_coredns"></a> [enable\_amazon\_eks\_coredns](#input\_enable\_amazon\_eks\_coredns) | Enable Amazon EKS CoreDNS add-on | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_kube_proxy"></a> [enable\_amazon\_eks\_kube\_proxy](#input\_enable\_amazon\_eks\_kube\_proxy) | Enable Kube Proxy add-on | `bool` | `false` | no |
| <a name="input_enable_aws_node_termination_handler"></a> [enable\_aws\_node\_termination\_handler](#input\_enable\_aws\_node\_termination\_handler) | Enable AWS Node Termination Handler add-on | `bool` | `false` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable Cluster autoscaler add-on | `bool` | `false` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Enable metrics server add-on | `bool` | `false` | no |
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
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_region2"></a> [region2](#input\_region2) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name to use for the VPC | `string` | `"my-vpc"` | no |
| <a name="input_zarf_version"></a> [zarf\_version](#input\_zarf\_version) | The version of Zarf to use | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The ID of the bastion host |
| <a name="output_bastion_private_key"></a> [bastion\_private\_key](#output\_bastion\_private\_key) | The private key for the bastion host |
| <a name="output_dynamodb_name"></a> [dynamodb\_name](#output\_dynamodb\_name) | Name of DynmoDB table |
| <a name="output_keycloak_db_instance_endpoint"></a> [keycloak\_db\_instance\_endpoint](#output\_keycloak\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_keycloak_db_instance_name"></a> [keycloak\_db\_instance\_name](#output\_keycloak\_db\_instance\_name) | The database name |
| <a name="output_keycloak_db_instance_port"></a> [keycloak\_db\_instance\_port](#output\_keycloak\_db\_instance\_port) | The database port |
| <a name="output_keycloak_db_instance_username"></a> [keycloak\_db\_instance\_username](#output\_keycloak\_db\_instance\_username) | The master username for the database |
| <a name="output_loki_s3_bucket"></a> [loki\_s3\_bucket](#output\_loki\_s3\_bucket) | Loki S3 Bucket Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

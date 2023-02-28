# EKS Cluster Deployment with new VPC & Big Bang Dependencies

This example deploys the following Basic EKS Cluster with VPC

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
      - [Step 2: Modify terraform.tfvars (located in tmp directory) with desired values.](#step-2-modify-terraformtfvars-located-in-tmp-directory-with-desired-values)
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

#### Step 2: Modify terraform.tfvars (located in tmp directory) with desired values.

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
export AWS_DEFAULT_REGION=us-east-2 #set to your perferred region

popd

cp backend.tf.example backend.tf

#copy init and copy state if it exists
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

Navigate back to the terminal in the complete-self-managed-nodegroup directory and Provision the EKS Cluster

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

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.53.0 |

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
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign a public IP to the bastion | `bool` | `false` | no |
| <a name="input_aws_admin_usernames"></a> [aws\_admin\_usernames](#input\_aws\_admin\_usernames) | A list of one or more AWS usernames with authorized access to KMS and EKS resources | `list(string)` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use for deployment | `string` | n/a | yes |
| <a name="input_bastion_ami_id"></a> [bastion\_ami\_id](#input\_bastion\_ami\_id) | (Optional) The AMI ID to use for the bastion, will query the latest Amazon Linux 2 AMI if not provided | `string` | `""` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | value for the instance type of the EKS worker nodes | `string` | `"m5.xlarge"` | no |
| <a name="input_bastion_name"></a> [bastion\_name](#input\_bastion\_name) | The name to use for the bastion | `string` | `"my-bastion"` | no |
| <a name="input_bastion_ssh_password"></a> [bastion\_ssh\_password](#input\_bastion\_ssh\_password) | The SSH password to use for the bastion if SSM authentication is used | `string` | `"my-password"` | no |
| <a name="input_bastion_ssh_user"></a> [bastion\_ssh\_user](#input\_bastion\_ssh\_user) | The SSH user to use for the bastion | `string` | `"ec2-user"` | no |
| <a name="input_bastion_tenancy"></a> [bastion\_tenancy](#input\_bastion\_tenancy) | The tenancy of the bastion | `string` | `"default"` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable private access to the EKS cluster | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to use for the EKS cluster | `string` | `"my-eks"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Whether to create a database subnet group | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Whether to create a database subnet route table | `bool` | `true` | no |
| <a name="input_eks_k8s_version"></a> [eks\_k8s\_version](#input\_eks\_k8s\_version) | The Kubernetes version to use for the EKS cluster | `string` | `"1.23"` | no |
| <a name="input_eks_worker_tenancy"></a> [eks\_worker\_tenancy](#input\_eks\_worker\_tenancy) | The tenancy of the EKS worker nodes | `string` | `"default"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | value for the instance type of the EKS worker nodes | `string` | `"m5.xlarge"` | no |
| <a name="input_kc_db_allocated_storage"></a> [kc\_db\_allocated\_storage](#input\_kc\_db\_allocated\_storage) | The database allocated storage to use for Keycloak | `number` | n/a | yes |
| <a name="input_kc_db_engine_version"></a> [kc\_db\_engine\_version](#input\_kc\_db\_engine\_version) | The database engine to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_family"></a> [kc\_db\_family](#input\_kc\_db\_family) | The database family to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_instance_class"></a> [kc\_db\_instance\_class](#input\_kc\_db\_instance\_class) | The database instance class to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_major_engine_version"></a> [kc\_db\_major\_engine\_version](#input\_kc\_db\_major\_engine\_version) | The database major engine version to use for Keycloak | `string` | n/a | yes |
| <a name="input_kc_db_max_allocated_storage"></a> [kc\_db\_max\_allocated\_storage](#input\_kc\_db\_max\_allocated\_storage) | The database allocated storage to use for Keycloak | `number` | n/a | yes |
| <a name="input_keycloak_db_password"></a> [keycloak\_db\_password](#input\_keycloak\_db\_password) | The password to use for the Keycloak database | `string` | `"my-password"` | no |
| <a name="input_keycloak_enabled"></a> [keycloak\_enabled](#input\_keycloak\_enabled) | Whether to enable Keycloak | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_region2"></a> [region2](#input\_region2) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_instance_tenancy"></a> [vpc\_instance\_tenancy](#input\_vpc\_instance\_tenancy) | The tenancy of instances launched into the VPC | `string` | `"default"` | no |
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

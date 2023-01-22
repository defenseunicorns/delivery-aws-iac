# EKS Cluster Deployment with new VPC

This example deploys the following Basic EKS Cluster with VPC

- Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
- Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- Creates EKS Cluster Control plane with one managed node group
- Creates a Bastion host in a private subnet
- Creates dependencies needed for BigBang

## How to Deploy

### Prerequisites

Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run Terraform Plan and Apply

1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [Kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
4. [SSHuttle](https://github.com/sshuttle/sshuttle)

Ensure that your AWS credentials are configured. This can be done by running `aws configure`

### Deployment Steps

#### Step 1: Preparation

```sh
mkdir tmp 
git clone https://github.com/defenseunicorns/iac.git
cd tmp/examples/complete-example/
mv terraform.tfvars.example ../../../terraform.tfvars
```

Modify terraform.tfvars (located in tmp directory) with desired values

Initialize a working directory with configuration files and create local terraform state file 

```sh
terraform init
```

Alternatively, you can provision an S3 backend prior to this step using the tf-state-backend example and init via the following:

```sh
cd tmp/examples/tf-state-backend
terraform apply

cd tmp/examples/complete-example
mv backend.example backend.tf
tf init -backend-config="bucket=<bucket_id from output of previous apply>" \
-backend-config="key=complete-example/terraform.tfstate" \
-backend-config="dynamodb_table=<table_name from output of previous apply>" \
-backend-config="region=<region from tfvars file"
```

#### Step 3: Provision VPC and Bastion

```sh
terraform plan -var-file ../../../complete-example.tfvars -target=module.vpc -target=module.bastion
# verify these changes are desired
terraform apply -var-file ../../../complete-example.tfvars -target=module.vpc -target=module.bastion
# type yes to confirm or utilize the ```-auto-approve``` flag in the above command
```

#### Step 4: Connect to the Bastion using SSHuttle and Provision the remaining Infrastucture

Add the following to your ~/.ssh/config to connect to the Bastion via AWS SSM (create config file if it does not exist)

```sh
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

Test SSH connection to the Bastion 

```sh
# replace "my-password" with the variable set if changed from the default
expect -c 'spawn ssh ec2-user@<bastion instance id> ; expect "assword:"; send "my-password\r"; interact'
```

In a new terminal, open an sshuttle tunnel to the bastion

```sh
sudo expect -c 'spawn sshuttle --dns -vr ec2-user@<bastion instance id> <vpc cidr block> ; expect "assword:"; send "my-password\r"; interact'
```

Navigate back to the terminal in the complete-example directory and Provision the EKS Cluster

```sh
terraform apply -var-file ../../../complete-example.tfvars
# type yes to confirm or utilize the ```-auto-approve``` flag in the above command
```

### Configure `kubectl` and test cluster

Note: In this example we are using a private EKS Cluster endpoint for the control plane. You must ensure the sshuttle is running to the bastion to utilize `kubectl`

EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster.
This following command used to update the `kubeconfig` in your local machine where you run kubectl commands to interact with your EKS Cluster.

#### Step 5: Run `update-kubeconfig` command

`~/.kube/config` file gets updated with cluster details and certificate from the below command

    aws eks --region <enter-your-region> update-kubeconfig --name <cluster-name>

#### Step 6: List all the worker nodes by running the command below

    kubectl get nodes

#### Step 7: List all the pods running in `kube-system` namespace

    kubectl get pods -n kube-system

## Cleanup

To clean up your environment, destroy the Terraform modules in reverse order.

Destroy the Kubernetes Add-ons, EKS cluster with Node groups and VPC

```sh
terraform destroy -var-file ../../../complete-example.tfvars -auto-approve
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.51.0 |

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
| [aws_eks_cluster.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | The AWS account to deploy into | `string` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign a public IP to the bastion | `bool` | `false` | no |
| <a name="input_aws_admin_1_username"></a> [aws\_admin\_1\_username](#input\_aws\_admin\_1\_username) | The AWS admin username to use for deployment | `string` | n/a | yes |
| <a name="input_aws_admin_2_username"></a> [aws\_admin\_2\_username](#input\_aws\_admin\_2\_username) | The AWS admin username to use for deployment | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use for deployment | `string` | n/a | yes |
| <a name="input_bastion_ami_id"></a> [bastion\_ami\_id](#input\_bastion\_ami\_id) | The AMI ID to use for the bastion | `string` | `"ami-000d4884381edb14c"` | no |
| <a name="input_bastion_name"></a> [bastion\_name](#input\_bastion\_name) | The name to use for the bastion | `string` | `"my-bastion"` | no |
| <a name="input_bastion_ssh_password"></a> [bastion\_ssh\_password](#input\_bastion\_ssh\_password) | The SSH password to use for the bastion if SSM authentication is used | `string` | `"my-password"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to use for the EKS cluster | `string` | `"my-eks"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Whether to create a database subnet group | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Whether to create a database subnet route table | `bool` | `true` | no |
| <a name="input_eks_k8s_version"></a> [eks\_k8s\_version](#input\_eks\_k8s\_version) | The Kubernetes version to use for the EKS cluster | `string` | `"1.23"` | no |
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
| <a name="input_ssh_user"></a> [ssh\_user](#input\_ssh\_user) | The SSH user to use for the bastion | `string` | `"ec2-user"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name to use for the VPC | `string` | `"my-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The ID of the bastion host |
| <a name="output_bastion_private_key"></a> [bastion\_private\_key](#output\_bastion\_private\_key) | The private key for the bastion host |
| <a name="output_keycloak_db_instance_endpoint"></a> [keycloak\_db\_instance\_endpoint](#output\_keycloak\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_keycloak_db_instance_name"></a> [keycloak\_db\_instance\_name](#output\_keycloak\_db\_instance\_name) | The database name |
| <a name="output_keycloak_db_instance_port"></a> [keycloak\_db\_instance\_port](#output\_keycloak\_db\_instance\_port) | The database port |
| <a name="output_keycloak_db_instance_username"></a> [keycloak\_db\_instance\_username](#output\_keycloak\_db\_instance\_username) | The master username for the database |
| <a name="output_loki_s3_bucket"></a> [loki\_s3\_bucket](#output\_loki\_s3\_bucket) | Loki S3 Bucket Name |

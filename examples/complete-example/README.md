# EKS Cluster Deployment with new VPC

This example deploys the following Basic EKS Cluster with VPC

- Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
- Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- Creates EKS Cluster Control plane with one managed node group
- Creates a Bastion host
- Creates dependencies needed for BigBang

## How to Deploy

### Prerequisites

Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run Terraform Plan and Apply

1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [Kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Minimum IAM Policy

> **Note**: The policy resource is set as `*` to allow all resources, this is not a recommended practice.
You can find the policy [here](min-iam-policy.json)


### Deployment Steps

#### Step 1: Preparation

```sh
git clone https://github.com/defenseunicorns/iac.git
cd examples/complete-example/
```
Modify locals.tf in root module with desired values

Initialize a working directory with configuration files and create local terraform state file 

```sh
terraform init
```



#### Step 2: Migrate Terraform State (OPTIONAL)

```sh
terraform apply -target=module.tfstate_backend
```

Uncomment the backend.tf & add the output tfstate-backend bucket name (output from the apply above) along with other desired values (i.e. region)

```sh
terraform init -migrate-state -auto-approve

```

#### Step 3: Run Terraform PLAN

Verify the resources created by this execution

```sh
export AWS_REGION=<ENTER YOUR REGION>   # Select your own region if not set in locals
terraform plan
```

#### Step 4: Finally, Terraform APPLY

**Deploy the pattern**

```sh
terraform apply
```

Enter `yes` to apply.

### Configure `kubectl` and test cluster

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
terraform destroy -target="module.bigbang-dependencies" -auto-approve
terraform destroy -target="module.bastion" -auto-approve
terraform destroy -target="module.eks" -auto-approve
terraform destroy -target="module.vpc" -auto-approve

# or the YOLO way
# comment out all lines in the backend.tf
terraform init -migrate-state
terraform destroy -auto-approve
```

Finally, destroy any additional resources that are not in the above modules

```sh
terraform destroy -auto-approve
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.46.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ../../modules/eks | n/a |
| <a name="module_flux_sops"></a> [flux\_sops](#module\_flux\_sops) | ../../modules/sops | n/a |
| <a name="module_loki_s3_bucket"></a> [loki\_s3\_bucket](#module\_loki\_s3\_bucket) | ../../modules/s3-irsa | n/a |
| <a name="module_rds_postgres_keycloak"></a> [rds\_postgres\_keycloak](#module\_rds\_postgres\_keycloak) | ../../modules/rds | n/a |
| <a name="module_tfstate_backend"></a> [tfstate\_backend](#module\_tfstate\_backend) | ../../modules/tfstate-backend | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keycloak_db_instance_endpoint"></a> [keycloak\_db\_instance\_endpoint](#output\_keycloak\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_keycloak_db_instance_name"></a> [keycloak\_db\_instance\_name](#output\_keycloak\_db\_instance\_name) | The database name |
| <a name="output_keycloak_db_instance_port"></a> [keycloak\_db\_instance\_port](#output\_keycloak\_db\_instance\_port) | The database port |
| <a name="output_keycloak_db_instance_username"></a> [keycloak\_db\_instance\_username](#output\_keycloak\_db\_instance\_username) | The master username for the database |
| <a name="output_loki_s3_bucket"></a> [loki\_s3\_bucket](#output\_loki\_s3\_bucket) | Loki S3 Bucket Name |
| <a name="output_tfstate_bucket_id"></a> [tfstate\_bucket\_id](#output\_tfstate\_bucket\_id) | Terraform State Bucket Name |

########################
# --- Mission Init --- #
########################
module "mission_init" {
  source                          = "./modules/mission-init"
  deploy_id                       = var.deploy_id
  impact_level                    = "devx"
  permissions_boundary_policy_arn = var.permissions_boundary_policy_arn
  stage                           = "demo"
}

#######################
# --- Private VPC --- #
#######################
module "private_vpc" {
  source                  = "git::https://github.com/defenseunicorns/terraform-aws-uds-vpc.git?ref=v0.1.5"
  vpc_requirements        = { azs = module.mission_init.azs }
  deployment_requirements = module.mission_init.deployment_requirements // TODO: When deploying devx, 2 problems happen
  // 1 private already has a 0.0.0.0 route to the NAT Gateway -- TGW conflict
  // 2 devx = 1 route table, il5 = 3 route tables
  vpc_advanced_overrides = {
    create_igw         = false
    enable_nat_gateway = false
    single_nat_gateway = false
    vpc_cidr = var.vpc_cidr
  }
}

###############
# --- EKS --- #
###############
locals {
  eks_requirements = {
    default_ami_id = module.mission_init.amis["eks-cpu"].id
    region         = module.mission_init.region
  }
}
module "uds_eks" {
  # source = "../../../../../terraform-aws-uds-eks"
  source                  = "git::https://github.com/defenseunicorns/terraform-aws-uds-eks.git?ref=v0.2.1"
  vpc_properties          = module.private_vpc.vpc_properties
  eks_requirements        = local.eks_requirements
  deployment_requirements = module.mission_init.deployment_requirements
  eks_options = {
    additional_eks_admin_arns = [
      "arn:${module.mission_init.aws_partition}:iam::${module.mission_init.aws_caller_identity.account_id}:role/${module.bastion_label.id}",
    ]
    default_self_managed_node_group = {
      allowed_instance_types = ["m5a.2xlarge", "m5a.4xlarge"]
      memory_mib             = { min = 4000 }
      vcpu_count             = { min = 2 }
    }
  }
}

####################
# --- UDS Core --- #
####################

# Deploys all uds core infra dependencies (like keycloak db, )
module "uds_core" {
  # checkov:skip=CKV_TF_2: "Ensure Terraform module sources use a tag with a version number"
  source                  = "git::https://github.com/defenseunicorns/terraform-aws-uds-eks-core.git?ref=v0.0.8"
  vpc_properties          = module.private_vpc.vpc_properties
  deployment_requirements = module.mission_init.deployment_requirements
  eks_properties          = module.uds_eks.eks_properties
}



###########################
# --- Private Bastion --- #
###########################

module "bastion_label" {
  source      = "cloudposse/label/null"
  version     = "v0.25.0"
  namespace   = "uds"
  stage       = module.mission_init.deployment_requirements.stage
  tenant      = module.mission_init.deployment_requirements.deploy_id
  name        = "bastion"
  delimiter   = "-"
  label_order = ["namespace", "name", "stage", "tenant"]
}

module "bastion" {
  source                  = "git::https://github.com/defenseunicorns/terraform-aws-uds-bastion.git?ref=v0.0.1"
  deployment_requirements = module.mission_init.deployment_requirements
  vpc_properties          = module.private_vpc.vpc_properties
  bastion_requirements = {
    ami      = module.mission_init.amis["bastion"].id
    key_name = aws_key_pair.bastion.id
  }
  ec2_instance_advanced_overrides = {
    user_data_base64 = data.cloudinit_config.bastion.rendered // TODO: Move to options?
  }
}

#############################
# --- Bastion User Data --- #
#############################

data "cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/templates/user_data.sh.tpl",
      {
        aws_region                            = module.mission_init.region
        ssh_user                              = "ec2-user"
        ssh_password                          = "" //var.ssh_password
        keys_update_frequency                 = "*/5 * * * *"
        enable_hourly_cron_updates            = true
        additional_user_data_script           = ""
        ssm_enabled                           = true
        secrets_manager_secret_id             = ""
        zarf_version                          = ""
        uds_cli_version                       = "v0.11.0"
        ssm_parameter_name                    = module.bastion_label.id
        enable_log_to_cloudwatch              = false
        max_ssm_connections                   = 10
        terminate_oldest_ssm_connection_first = true
        max_ssh_sessions                      = 10
      }
    )
  }
}

################################
# --- Bastion SSH Key Pair --- #
################################

# Generate key pair
resource "tls_private_key" "bastion_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key locally (optional)
resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion_ssh_key.private_key_pem
  filename = abspath("${path.root}/ignore/${module.bastion_label.id}.generated_key.pem")

  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}" # Secure the private key
  }
}

# Save the public key locally (optional)
resource "local_file" "bastion_public_key" {
  content  = tls_private_key.bastion_ssh_key.public_key_openssh
  filename = abspath("${path.root}/ignore/${module.bastion_label.id}.generated_key.pub")
}

# Create AWS Key Pair
resource "aws_key_pair" "bastion" {
  key_name   = module.bastion_label.id
  public_key = tls_private_key.bastion_ssh_key.public_key_openssh
}

resource "local_file" "bastion_ssh_config" {
  content  = <<-EOF
Host ${module.bastion.bastion_properties.instance_id}
  User ec2-user
  ServerAliveInterval 60
  ServerAliveCountMax 3
  CheckHostIP no
  StrictHostKeyChecking no
  IdentityFile ${local_file.bastion_private_key.filename}
  IdentitiesOnly yes
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  ProxyCommand aws ssm --region ${module.mission_init.region} start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
  EOF
  filename = abspath("./ignore/${module.bastion_label.id}-ssh-config")
}

###############################
# --- Public Access Layer --- #
###############################

module "public_access_layer" {
  source = "./modules/public-access-layer"
  public_access_layer_requirements = {
    azs                     = module.mission_init.azs
    deployment_requirements = module.mission_init.deployment_requirements
    private_vpc_properties  = module.private_vpc.vpc_properties
    vpc_requirements        = module.mission_init.azs
  }
}

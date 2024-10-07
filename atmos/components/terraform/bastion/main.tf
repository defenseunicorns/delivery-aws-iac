terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
  }
}


# This module shall be vendored in via atmos vendor workflow.
# Guiding principles:
# * Defense Unicorns wrapper for existing official modules from Amazon
# * Common interface via variable classes. Make it obvious to the consumer what is required and what is senstive. Senstive info if combined with non-senstive will mask non-senstive info in deployment output, complicating troubleshooting.
#   * top level vars for non-senstive required inputs (no default values, validation desired)
#   * top level vars for senstive required inputs (no default values, validation desired)
#   * single top level config object for non-senstive optional inputs (default values required, validation desired)
#   * single top level config object for senstive optional inputs (default values required, validation desired)
# * perfer distinct smaller modules as part of an assembly over complex conditinal logic to statify all Impact Level requirements
# * context provider for common config, tags and labels
# *
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

variable "bastion_required_var1" {}
variable "bastion_required_var2" {}
variable "bastion_sensitive_required_var1" {
  sensitive = true
}
variable "bastion_config_opts" {
  type = object({
    default_ami_id = optional(string)
  })
}
variable "bastion_sensitive_config_opts" {
  sensitive = true
  type = object({
    bastion_sensitive_opt1 = optional(string)
    bastion_sensitive_opt2 = optional(string)
  })
}


### Current Var's in legacy module
locals {
  base_bastion_config = {
    name                                 = data.context_label.this.rendered
    region                               = "" # TODO: From init
    vpc_id                               = "" # TODO: From input object, mapped to vpc module
    additional_user_data_script          = ""
    allowed_public_ips                   = []
    ami_id                               = var.bastion_config_opts.default_ami_id
    assign_public_ip                     = false
    bastion_instance_tags                = {}
    bastion_secondary_ebs_volume_size    = "70"
    ebs_optimized                        = true
    enable_bastion_terraform_permissions = false
    enable_log_to_cloudwatch             = false
    enable_secondary_ebs_volume          = false
    # eni_attachment_config                 = null #TODO: Does this need to come from input object or just be null?
    instance_type        = "m5.large"
    max_ssh_sessions     = 1
    max_ssm_connections  = 1
    monitoring           = true
    permissions_boundary = ""
    policy_arns          = []
    #policy_content                        = null #TODO: From init or just opinionated no?
    private_ip                            = null
    root_volume_config                    = { "volume_size" : "20", "volume_type" : "gp3" }
    secrets_manager_secret_id             = ""
    security_group_ids                    = []
    ssh_password                          = ""
    ssh_user                              = "ec2-user"
    ssm_enabled                           = true
    subnet_id                             = ""
    subnet_name                           = ""
    tags                                  = data.context_tags.this.tags
    tenancy                               = "default"
    terminate_oldest_ssm_connection_first = false
    uds_cli_version                       = "v0.11.0"
    user_data_override                    = ""
    zarf_version                          = ""
  }



  role_name = "${local.bastion_config.name}-role"
  # add_custom_policy_to_role = local.bastion_config.policy_content != null

  # ssh access
  keys_update_frequency      = "*/5 * * * *"
  enable_hourly_cron_updates = true

  security_group_configs = [{
    name        = "${local.bastion_config.name}-sg"
    description = "SG for ${local.bastion_config.name}"
    vpc_id      = local.bastion_config.vpc_id
    ingress_rules = [{
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = local.bastion_config.allowed_public_ips # admin IPs or private IP (internal) of Software Defined Perimeter
      description = "SSH access"
      },
    ]
    egress_rules = [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }]
  }]


  bastion_config = local.base_bastion_config
}






######## Legacy DU Module


data "aws_region" "current" {}

data "aws_partition" "current" {}

#### Dynamic AMI selection
#TODO: Do we move this to the 'mission init' module?
# data "aws_ami" "from_filter" {
#   count       = local.bastion_config.ami_id != "" ? 0 : 1
#   most_recent = true
#
#   filter {
#     name   = "name"
#     values = [local.bastion_config.ami_name_filter]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = [local.bastion_config.ami_virtualization_type]
#   }
#
#   owners = [local.bastion_config.ami_canonical_owner]
# }

data "aws_subnet" "subnet_by_name" {
  count = local.bastion_config.subnet_name != "" ? 1 : 0
  tags = {
    Name : local.bastion_config.subnet_name
  }
}

resource "aws_instance" "application" {
  #TODO: Move all logic out of this block, and set back before the config object is selected

  #checkov:skip=CKV2_AWS_41: IAM role is created in the module
  ami                         = local.bastion_config.ami_id #TODO: Get from input object linked to init outputs
  instance_type               = local.bastion_config.instance_type
  vpc_security_group_ids      = length(local.security_group_configs) > 0 ? aws_security_group.sg[*].id : local.bastion_config.security_group_ids
  user_data                   = local.bastion_config.user_data_override != null ? local.bastion_config.user_data_override : data.cloudinit_config.config.rendered
  iam_instance_profile        = local.role_name == "" ? null : aws_iam_instance_profile.bastion_ssm_profile.name
  ebs_optimized               = local.bastion_config.ebs_optimized
  associate_public_ip_address = local.bastion_config.assign_public_ip
  monitoring                  = local.bastion_config.monitoring
  tenancy                     = local.bastion_config.tenancy
  private_ip                  = local.bastion_config.private_ip
  root_block_device {
    volume_size = local.bastion_config.root_volume_config.volume_size
    volume_type = local.bastion_config.root_volume_config.volume_type
    encrypted   = true
  }
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  subnet_id = local.bastion_config.subnet_name != "" ? data.aws_subnet.subnet_by_name[0].id : local.bastion_config.subnet_id

  tags = merge(
    local.bastion_config.tags,
    local.bastion_config.bastion_instance_tags,
    { Name = local.bastion_config.name },
  )
}

# TODO: Decide what do do with this...input from init or just opinionated no
# resource "aws_network_interface_attachment" "attach" {
#   count                = local.bastion_config.eni_attachment_config != null ? length(local.bastion_config.eni_attachment_config) : 0
#   instance_id          = aws_instance.application.id
#   network_interface_id = local.bastion_config.eni_attachment_config[count.index].network_interface_id
#   device_index         = local.bastion_config.eni_attachment_config[count.index].device_index
# }

# Optional Security Group
resource "aws_security_group" "sg" {
  # checkov:skip=CKV_AWS_23: "Ensure every security groups rule has a description" -- False positive
  count       = length(local.security_group_configs)
  name        = local.security_group_configs[count.index].name
  description = local.security_group_configs[count.index].description
  vpc_id      = local.security_group_configs[count.index].vpc_id

  # dynamic "ingress" {
  #   for_each = local.security_group_configs[count.index].ingress_rules

  #   content {
  #     from_port   = ingress.value.from_port
  #     to_port     = ingress.value.to_port
  #     protocol    = ingress.value.protocol
  #     cidr_blocks = ingress.value.cidr_blocks
  #     description = ingress.value.description
  #   }
  # }

  dynamic "egress" {
    for_each = local.security_group_configs[count.index].egress_rules

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}

#####################################################
##################### user data #####################

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/templates/user_data.sh.tpl",
      {
        aws_region                            = local.bastion_config.region
        ssh_user                              = local.bastion_config.ssh_user
        ssh_password                          = local.bastion_config.ssh_password
        keys_update_frequency                 = local.keys_update_frequency
        enable_hourly_cron_updates            = local.enable_hourly_cron_updates
        additional_user_data_script           = local.bastion_config.additional_user_data_script
        ssm_enabled                           = local.bastion_config.ssm_enabled
        secrets_manager_secret_id             = local.bastion_config.secrets_manager_secret_id
        zarf_version                          = local.bastion_config.zarf_version
        uds_cli_version                       = local.bastion_config.uds_cli_version
        ssm_parameter_name                    = local.bastion_config.name
        enable_log_to_cloudwatch              = local.bastion_config.enable_log_to_cloudwatch
        max_ssm_connections                   = local.bastion_config.max_ssm_connections
        terminate_oldest_ssm_connection_first = local.bastion_config.terminate_oldest_ssm_connection_first
        max_ssh_sessions                      = local.bastion_config.max_ssh_sessions
      }
    )
  }
}

resource "aws_ebs_volume" "bastion_secondary_ebs_volume" {
  count             = local.bastion_config.enable_secondary_ebs_volume ? 1 : 0
  availability_zone = aws_instance.application.availability_zone
  size              = local.bastion_config.bastion_secondary_ebs_volume_size
  encrypted         = true
  tags              = local.bastion_config.tags
}

resource "aws_volume_attachment" "ebs_attachment" {
  count       = local.bastion_config.enable_secondary_ebs_volume ? 1 : 0
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.bastion_secondary_ebs_volume[0].id
  instance_id = aws_instance.application.id
}


### Legacy Module End


output "bastion_required_out1" {
  value = var.bastion_required_var1
}

output "bastion_required_out2" {
  value = var.bastion_required_var2
}

output "bastion_sensitive_required_out1" {
  sensitive = true
  value     = var.bastion_sensitive_required_var1
}

output "bastion_opt_config_out" {
  value = var.bastion_config_opts
}
output "bastion_sensitive_opt_config_out" {
  sensitive = true
  value     = var.bastion_sensitive_config_opts
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_ami" "from_filter" {
  count       = var.ami_id != "" ? 0 : 1
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_virtualization_type]
  }

  owners = [var.ami_canonical_owner]
}

data "aws_subnet" "subnet_by_name" {
  count = var.subnet_name != "" ? 1 : 0
  tags = {
    Name : var.subnet_name
  }
}

data "aws_s3_bucket" "access_logs_bucket" {
  bucket = var.access_logs_bucket_name
}

data "aws_kms_key" "default" {
  key_id = var.kms_key_arn
}

resource "aws_instance" "application" {
  #checkov:skip=CKV2_AWS_41: IAM role is created in the module
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.from_filter[0].id
  instance_type               = var.instance_type
  vpc_security_group_ids      = length(local.security_group_configs) > 0 ? aws_security_group.sg[*].id : var.security_group_ids
  user_data                   = data.cloudinit_config.config.rendered
  iam_instance_profile        = local.role_name == "" ? null : aws_iam_instance_profile.bastion_ssm_profile.name
  ebs_optimized               = true
  associate_public_ip_address = var.assign_public_ip
  monitoring                  = true
  tenancy                     = var.tenancy
  root_block_device {
    volume_size = var.root_volume_config.volume_size
    volume_type = var.root_volume_config.volume_type
    encrypted   = true
  }
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  subnet_id = var.subnet_name != "" ? data.aws_subnet.subnet_by_name[0].id : var.subnet_id

  tags = merge(
    var.tags,
    { Name = var.name }
  )
}

resource "aws_network_interface_attachment" "attach" {
  count                = var.eni_attachment_config != null ? length(var.eni_attachment_config) : 0
  instance_id          = aws_instance.application.id
  network_interface_id = var.eni_attachment_config[count.index].network_interface_id
  device_index         = var.eni_attachment_config[count.index].device_index
}

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

resource "aws_sqs_queue" "bastion_login_queue" {
  count                             = var.enable_sqs_events_on_bastion_login ? 1 : 0
  name                              = local.sqs_queue_name
  kms_master_key_id                 = data.aws_kms_key.default.arn
  kms_data_key_reuse_period_seconds = 300
  visibility_timeout_seconds        = 300

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSend",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:${data.aws_partition.current.partition}:sqs:*:*:${local.sqs_queue_name}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${data.aws_s3_bucket.access_logs_bucket.arn}" }
      }
    }
  ]
}
POLICY
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
        s3_bucket_name              = data.aws_s3_bucket.access_logs_bucket.id
        s3_bucket_uri               = "s3://${data.aws_s3_bucket.access_logs_bucket.id}"
        aws_region                  = var.region
        ssh_user                    = var.ssh_user
        keys_update_frequency       = local.keys_update_frequency
        enable_hourly_cron_updates  = local.enable_hourly_cron_updates
        additional_user_data_script = var.additional_user_data_script
        ssm_enabled                 = var.ssm_enabled
        ssh_password                = var.ssh_password
        zarf_version                = var.zarf_version
        ssm_parameter_name          = var.name
      }
    )
  }
}

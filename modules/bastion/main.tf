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

resource "aws_instance" "application" {
  #checkov:skip=CKV_AWS_126: Not using aws detailed monitoring at this time
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.from_filter[0].id
  instance_type               = local.instance_type
  key_name                    = var.ec2_key_name
  vpc_security_group_ids      = length(local.security_group_configs) > 0 ? aws_security_group.sg.*.id : var.security_group_ids
  user_data                   = data.cloudinit_config.config.rendered
  iam_instance_profile        = local.role_name == "" ? null : aws_iam_instance_profile.profile[0].name
  ebs_optimized = true
  associate_public_ip_address = var.assign_public_ip
  security_groups = [aws_security_group.sg.id]
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

  tags = {
    Name = var.name
  }
}

resource "aws_network_interface_attachment" "attach" {
  count                = var.eni_attachment_config != null ? length(var.eni_attachment_config) : 0
  instance_id          = aws_instance.application.id
  network_interface_id = var.eni_attachment_config[count.index].network_interface_id
  device_index         = var.eni_attachment_config[count.index].device_index
}

resource "aws_iam_instance_profile" "profile" {
  count = local.role_name == "" ? 0 : 1
  name  = "${local.role_name}-profile"
  role  = aws_iam_role.role[0].name
}

resource "aws_iam_role" "role" {
  count                = local.role_name == "" ? 0 : 1
  name                 = local.role_name
  permissions_boundary = var.permissions_boundary

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "custom" {
  count       = local.role_name == "" || var.policy_content == "" ? 0 : 1
  name        = "${local.role_name}-policy"
  path        = "/"
  description = "Custom policy for EC2 instance"

  policy = var.policy_content
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = local.role_name == "" || var.policy_content == "" ? 0 : 1
  role       = aws_iam_role.role[0].name
  policy_arn = aws_iam_policy.custom[0].arn
}
resource "aws_iam_role_policy_attachment" "sops" {
  count      = var.add_sops_policy ? 1 : 0
  role       = aws_iam_role.role[0].name
  policy_arn = var.cluster_sops_policy_arn
}

resource "aws_iam_role_policy_attachment" "managed" {
  count      = local.role_name == "" ? 0 : length(var.policy_arns)
  role       = aws_iam_role.role[0].name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "s3_companion_cube" {
  role       = aws_iam_role.role[0].name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
}
resource "aws_iam_role_policy_attachment" "s3_logging_cube" {
  role       = aws_iam_role.role[0].name
  policy_arn = aws_iam_policy.s3_logging_policy.arn
}

resource "aws_iam_policy" "s3_readonly_policy" {
  name   = "${local.bucket_prefix}-s3-readonly"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListObject",
                "s3:GetObject"
            ],
            "Resource": [
              "${aws_s3_bucket.b.arn}/*",
              "${aws_s3_bucket.b.arn}"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_policy" "s3_logging_policy" {
  name   = "${local.bucket_prefix}-s3-logging"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:ListObject",
              "s3:GetObject",
              "s3:PutObject"
            ],
            "Resource": [
              "${aws_s3_bucket.log_bucket.arn}/*",
              "${aws_s3_bucket.log_bucket.arn}"
            ]
        }
    ]
}
EOF
}

# Optional Security Group
resource "aws_security_group" "sg" {
  count       = length(local.security_group_configs)
  name        = local.security_group_configs[count.index].name
  description = local.security_group_configs[count.index].description
  vpc_id      = local.security_group_configs[count.index].vpc_id

  dynamic "ingress" {
    for_each = local.security_group_configs[count.index].ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

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
##################### S3 Bucket #####################

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "b" {
  #checkov:skip=CKV_AWS_144:Do not want cross region replication
  #checkov:skip=CKV_AWS_145:Server side encryption is enabled
  bucket        = local.bucket_prefix

  force_destroy = var.force_destroy
  # Enabling logging for Cloutrail event
  # dynamic "aws_s3_bucket_logging" {
  #   for_each = length(keys(var.logging)) == 0 ? [] : [var.logging]

  #   content {
  #     target_bucket = logging.value.target_bucket
  #     target_prefix = lookup(logging.value, "target_prefix", null)
  #   }
  # }
}
resource "aws_s3_bucket_public_access_block" "access_b" {
  count = var.bucket_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.b.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "versioning_b" {
  count = var.versioning_enabled ? 1 : 0
  bucket = aws_s3_bucket.b.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_acl" "acl_b" {
  bucket = aws_s3_bucket.b.id
  acl    = var.acl
}
resource "aws_s3_bucket" "log_bucket" {
  #checkov:skip=CKV_AWS_144:Do not want cross region replication
  #checkov:skip=CKV_AWS_145:Server side encryption is enabled
  bucket = "${local.bucket_prefix}-logging"
  force_destroy = var.force_destroy
}
resource "aws_s3_bucket_versioning" "versioning_logging" {
  count = var.versioning_enabled ? 1 : 0
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  count = var.bucket_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}
resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.b.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.b.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# S3 Bucket policy requiring TLS to access Bucket
resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.b.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "AWS": "*"
      },
      "Action": [
				"s3:ListObject",
				"s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.b.arn}/*",
        "${aws_s3_bucket.b.arn}"
      ],
      "Effect": "Deny",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}
resource "aws_s3_bucket_policy" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "AWS": "*"
      },
      "Action": [
				"s3:ListObject",
				"s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.log_bucket.arn}/*",
        "${aws_s3_bucket.log_bucket.arn}"
      ],
      "Effect": "Deny",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_kms_key" "key" {
  count               = var.enable_event_queue ? 1 : 0
  description         = "KMS key for ${local.bucket_prefix} queue"
  enable_key_rotation = var.enable_kms_key_rotation
  policy              = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_caller_identity.current.arn}"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "S3 access",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": [
         "kms:GenerateDataKey",
         "kms:Decrypt"
      ],
      "Resource":  "*"
    },
    {
      "Sid": "Decrypt",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
         "kms:Decrypt"
      ],
      "Resource":  "*",
      "Condition": {
        "StringEquals": { "aws:PrincipalAccount": "${data.aws_caller_identity.current.account_id}" }
      }
    }
  ]
}
EOF
}

resource "aws_sqs_queue" "queue" {
  count                             = var.enable_event_queue ? 1 : 0
  name                              = "${local.bucket_prefix}-s3-event-notification-queue"
  kms_master_key_id                 = aws_kms_key.key[0].key_id
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
      "Resource": "arn:${data.aws_partition.current.partition}:sqs:*:*:${local.bucket_prefix}-s3-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.b.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.enable_event_queue ? 1 : 0
  bucket = aws_s3_bucket.b.id

  queue {
    queue_arn = aws_sqs_queue.queue[0].arn
    events    = ["s3:ObjectCreated:*"]
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
        s3_bucket_name              = aws_s3_bucket.b.id           // var.s3_bucket_name
        s3_bucket_uri               = "s3://${aws_s3_bucket.b.id}" // var.s3_bucket_uri
        aws_region                  = var.aws_region
        ssh_user                    = var.ssh_user
        keys_update_frequency       = local.keys_update_frequency
        enable_hourly_cron_updates  = local.enable_hourly_cron_updates
        additional_user_data_script = var.additional_user_data_script
      }
    )
  }
}

resource "aws_s3_object" "ssh_public_keys" {
  # Make sure that you put files into correct location and name them accordingly (`public-keys/{keyname}.pub`)
  source     = "./public-keys/${element(var.ssh_public_key_names, count.index)}.pub"
  depends_on = [aws_s3_bucket.b]

  count = length(var.ssh_public_key_names)

  bucket = aws_s3_bucket.b.bucket
  key    = "${element(var.ssh_public_key_names, count.index)}.pub"

}

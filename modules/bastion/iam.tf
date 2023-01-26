
# Create EC2 Instance Profile
resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# Create EC2 Instance Role
resource "aws_iam_role" "bastion_ssm_role" {
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

# Attach AmazonSSMManagedInstanceCore policy to role
data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-amazon-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

# Create S3/CloudWatch Logs access document, policy and attach to role
data "aws_iam_policy_document" "ssm_s3_cwl_access" {
  # checkov:skip=CKV_AWS_111: ADD REASON
  # A custom policy for S3 bucket access
  # https://docs.aws.amazon.com/en_us/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-custom-s3-policy
  statement {
    sid = "S3BucketAccessForSessionManager"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
    ]

    resources = [
      aws_s3_bucket.session_logs_bucket.arn,
      "${aws_s3_bucket.session_logs_bucket.arn}/*",
    ]
  }

  statement {
    sid = "S3EncryptionForSessionManager"

    actions = [
      "s3:GetEncryptionConfiguration",
    ]

    resources = [
      aws_s3_bucket.session_logs_bucket.arn
    ]
  }

  # A custom policy for CloudWatch Logs access
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/permissions-reference-cwl.html
  statement {
    sid = "CloudWatchLogsAccessForSessionManager"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }

  statement {
    sid = "KMSEncryptionForSessionManager"

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt",
    ]

    resources = [aws_kms_key.ssmkey.arn]
  }
}

resource "aws_iam_policy" "ssm_s3_cwl_access" {
  name   = "${var.name}-ssm_s3_cwl_access-${var.aws_region}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_s3_cwl_access.json
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-s3-cwl-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.ssm_s3_cwl_access.arn
}

# Create ssm_ec2_access document, policy and attachment
data "aws_iam_policy_document" "ssm_ec2_access" {
  statement {
    sid = "KMSEncryptionForSessionManager"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt",
    ]
    resources = [aws_kms_key.ssmkey.arn]
  }
  statement {
    actions = ["ssm:StartSession"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.application.id}",
      "arn:${data.aws_partition.current.partition}:ssm:*:*:document/AWS-StartSSHSession"
    ]
  }
}

resource "aws_iam_policy" "ssm_ec2_access" {
  name   = "ssm-${var.name}-${var.aws_region}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_ec2_access.json
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-ec2-access-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.ssm_ec2_access.arn
}

# Create custom policy and attachment
resource "aws_iam_policy" "custom" {
  count       = local.role_name == "" || var.policy_content == "" ? 0 : 1
  name        = "${local.role_name}-policy"
  path        = "/"
  description = "Custom policy for EC2 instance"

  policy = var.policy_content
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = local.role_name == "" || var.policy_content == "" ? 0 : 1
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Additional policy attachments if needed

resource "aws_iam_role_policy_attachment" "managed" {
  count      = local.role_name == "" ? 0 : length(var.policy_arns)
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = var.policy_arns[count.index]
}

# S3 readonly policy and attachment
resource "aws_iam_role_policy_attachment" "s3_companion_cube" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
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
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
              "${aws_s3_bucket.session_logs_bucket.arn}/*",
              "${aws_s3_bucket.session_logs_bucket.arn}"
            ]
        }
    ]
}
EOF
}

# S3 logging policy and attachment
resource "aws_iam_role_policy_attachment" "s3_logging_cube" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.s3_logging_policy.arn
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
              "s3:ListBucket",
              "s3:GetObject",
              "s3:PutObject"
            ],
            "Resource": [
              "${aws_s3_bucket.access_log_bucket.arn}/*",
              "${aws_s3_bucket.access_log_bucket.arn}"
            ]
        }
    ]
}
EOF
}

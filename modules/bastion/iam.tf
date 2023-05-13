
# Create EC2 Instance Profile
resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name

  tags = var.tags
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
  tags               = var.tags
}

# Attach AmazonSSMManagedInstanceCore policy to role
data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "bastion-ssm-aws-ssm-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

# Attach AmazonElasticFileSystemFullAccess policy to role
data "aws_iam_policy" "AmazonElasticFileSystemFullAccess" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-aws-efs-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = data.aws_iam_policy.AmazonElasticFileSystemFullAccess.arn
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

    resources = [data.aws_kms_key.default.arn]
  }
}

resource "aws_iam_policy" "ssm_s3_cwl_access" {
  name   = "${var.name}-ssm_s3_cwl_access-${var.region}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_s3_cwl_access.json

  tags = var.tags
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
    resources = [data.aws_kms_key.default.arn]
  }
  statement {
    actions = ["ssm:StartSession"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.application.id}",
      "arn:${data.aws_partition.current.partition}:ssm:*:*:document/AWS-StartSSHSession"
    ]
  }
}
# Create a custom policy for the bastion and attachment
resource "aws_iam_policy" "ssm_ec2_access" {
  name   = "ssm-${var.name}-${var.region}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_ec2_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-ec2-access-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.ssm_ec2_access.arn
}

# Create custom policy and attachment
resource "aws_iam_policy" "custom" {
  count       = local.add_custom_policy_to_role ? 1 : 0
  name        = "${local.role_name}-policy"
  path        = "/"
  description = "Custom policy for EC2 instance"

  policy = var.policy_content
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = local.add_custom_policy_to_role ? 1 : 0
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Additional policy attachments if needed

resource "aws_iam_role_policy_attachment" "managed" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = var.policy_arns[count.index]
}

# S3 readonly policy and attachment
resource "aws_iam_role_policy_attachment" "s3_companion_cube" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
}

resource "aws_iam_policy" "s3_readonly_policy" {
  name   = "${var.name}-s3-readonly"
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
  tags   = var.tags
}

# S3 logging policy and attachment
resource "aws_iam_role_policy_attachment" "s3_logging_cube" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.s3_logging_policy.arn
}

resource "aws_iam_policy" "s3_logging_policy" {
  name   = "${var.name}-s3-logging"
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
              "${data.aws_s3_bucket.access_logs_bucket.arn}/*",
              "${data.aws_s3_bucket.access_logs_bucket.arn}"
            ]
        }
    ]
}
EOF
  tags   = var.tags
}

# Terraform policy and attachment
resource "aws_iam_role_policy_attachment" "terraform" {
  count      = var.enable_bastion_terraform_permissions ? 1 : 0
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.terraform_policy[count.index].arn
}

resource "aws_iam_policy" "terraform_policy" {
  # checkov:skip=CKV_AWS_286: TODO: Tighten this policy up. It currently allows actions that can be used for privilege escalation without constraint. Ref: https://docs.bridgecrew.io/docs/ensure-iam-policies-does-not-allow-privilege-escalation
  # checkov:skip=CKV_AWS_110: TODO: Fix CKV_AWS_286. It is identical to this policy.
  # checkov:skip=CKV_AWS_287: TODO: Tighten this policy up. It currently allows actions that can be used for credentials exposure without constraint. Ref: https://docs.bridgecrew.io/docs/ensure-iam-policies-do-not-allow-credentials-exposure
  # checkov:skip=CKV_AWS_107: TODO: Fix CKV_AWS_287. It is identical to this policy.
  # checkov:skip=CKV_AWS_288: TODO: Tighten this policy up. It currently allows actions that can be used to exfiltrate secrets or other data without constraint. https://docs.bridgecrew.io/docs/ensure-iam-policies-do-not-allow-data-exfiltration
  # checkov:skip=CKV_AWS_108: TODO: Fix CKV_AWS_288. It is identical to this policy.
  # checkov:skip=CKV_AWS_289: TODO: Tighten this policy up. It currently allows actions that can be used for permissions management and/or resource exposure without constraint. Ref: https://docs.bridgecrew.io/docs/ensure-iam-policies-do-not-allow-permissions-management-resource-exposure-without-constraint
  # checkov:skip=CKV_AWS_109: TODO: Fix CKV_AWS_289. It is identical to this policy.
  # checkov:skip=CKV_AWS_290: TODO: Tighten this policy up. It currently allows actions that can be used to for resource exposure without constraint. Ref: https://docs.bridgecrew.io/docs/ensure-iam-policies-do-not-allow-write-access-without-constraint
  # checkov:skip=CKV_AWS_111: TODO: Fix CKV_AWS_290. It is identical to this policy.

  count = var.enable_bastion_terraform_permissions ? 1 : 0

  name   = "${var.name}-terraform-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:*",
                "aws-marketplace-management:*",
                "aws-marketplace:*",
                "cloudformation:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "events:*",
                "logs:*",
                "dynamodb:*",
                "glacier:*",
                "dms:*",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:ListInstance*",
                "iam:CreateInstanceProfile",
                "iam:UploadServerCertificate",
                "iam:UpdateServerCertificate",
                "iam:GetServerCertificate",
                "iam:DeleteServerCertificate",
                "iam:DetachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:PutRolePermissionsBoundary",
                "iam:PutRolePolicy",
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:AttachRolePolicy",
                "iam:*InstanceProfile",
                "iam:Generate*",
                "iam:Get*",
                "iam:List*",
                "iam:Sim*",
                "iam:Tag*",
                "iam:Untag*",
                "iam:*ServiceLinkedRole",
                "iam:CreateOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:UpdateAssumeRolePolicy",
                "ec2:*",
                "elasticbeanstalk:*",
                "elasticache:*",
                "elasticloadbalancing:*",
                "elasticmapreduce:*",
                "events:*",
                "glacier:*",
                "kinesis:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "ram:*",
                "rds:*",
                "redshift:*",
                "s3:*",
                "sns:*",
                "sqs:*",
                "swf:*",
                "tag:*",
                "workspaces:*",
                "ecs:*",
                "ecr:*",
                "inspector:Create*",
                "inspector:Delete*",
                "inspector:DescribeCrossAccountAccessRole",
                "inspector:DescribeAssessmentRuns",
                "inspector:DescribeAssessmentTargets",
                "inspector:DescribeAssessmentTemplates",
                "inspector:DescribeFindings",
                "inspector:DescribeResourceGroups",
                "inspector:DescribeRulesPackages",
                "inspector:List*",
                "inspector:PreviewAgents",
                "inspector:RemoveAttributesFromFindings",
                "inspector:SetTagsForResource",
                "inspector:StartAssessmentRun",
                "inspector:StopAssessmentRun",
                "inspector:SubscribeToEvent",
                "inspector:UnsubscribeFromEvent",
                "inspector:UpdateAssessmentTarget"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Sid": "EKSPermisssions",
            "Effect": "Allow",
            "Action": [
                "eks:UpdateNodegroupVersion",
                "eks:UpdateNodegroupConfig",
                "eks:UpdateClusterVersion",
                "eks:UpdateClusterConfig",
                "eks:UntagResource",
                "eks:TagResource",
                "eks:ListUpdates",
                "eks:ListTagsForResource",
                "eks:ListNodegroups",
                "eks:ListFargateProfiles",
                "eks:ListClusters",
                "eks:DescribeUpdate",
                "eks:DescribeNodegroup",
                "eks:DescribeFargateProfile",
                "eks:DescribeCluster",
                "eks:DeleteNodegroup",
                "eks:DeleteFargateProfile",
                "eks:DeleteCluster",
                "eks:CreateNodegroup",
                "eks:CreateFargateProfile",
                "eks:CreateCluster",
                "eks:CreateAddon",
                "eks:DeleteAddon",
                "eks:UpdateAddon",
                "eks:DescribeAddon",
                "eks:DescribeAddonVersions",
                "eks:ListAddons"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:DeleteRole"
            ],
            "Resource": [
                "arn:${data.aws_partition.current.partition}:iam::*:role/*-rke2-*",
                "arn:${data.aws_partition.current.partition}:iam::*:role/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:CreateRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:${data.aws_partition.current.partition}:iam::*:role/s3-dataRefresh"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "aws-portal:*Billing",
                "s3:PutBucketPublicAccessBlock",
                "s3:PutAccountPublicAccessBlock"
            ],
            "Resource": "*",
            "Effect": "Deny"
        }
    ]
}
EOF
  tags   = var.tags
}

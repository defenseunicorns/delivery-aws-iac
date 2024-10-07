# Create EC2 Instance Profile
resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "${local.bastion_config.name}-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name

  tags = local.bastion_config.tags
}

# Create EC2 Instance Role
resource "aws_iam_role" "bastion_ssm_role" {
  name                 = local.role_name
  permissions_boundary = local.bastion_config.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.bastion_config.tags
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

data "aws_iam_policy" "CloudWatchLogsFullAccess" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "bastion-ssm-s3-cwl-policy-attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = data.aws_iam_policy.CloudWatchLogsFullAccess.arn
}

# TODO: Do we remove this, or pass from init?
## Create custom policy and attachment
#resource "aws_iam_policy" "custom" {
#  count       = local.add_custom_policy_to_role ? 1 : 0
#  name        = "${local.role_name}-policy"
#  path        = "/"
#  description = "Custom policy for EC2 instance"
#
#  policy = local.bastion_config.policy_content
#  tags   = local.bastion_config.tags
#}

# resource "aws_iam_role_policy_attachment" "custom" {
#   count      = local.add_custom_policy_to_role ? 1 : 0
#   role       = aws_iam_role.bastion_ssm_role.name
#   policy_arn = aws_iam_policy.custom[0].arn
# }
#
# Additional policy attachments if needed

resource "aws_iam_role_policy_attachment" "managed" {
  count      = length(local.bastion_config.policy_arns)
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = local.bastion_config.policy_arns[count.index]
}

# Terraform policy and attachment
resource "aws_iam_role_policy_attachment" "terraform" {
  count      = local.bastion_config.enable_bastion_terraform_permissions ? 1 : 0
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
  # checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions" -- TODO: Update this policy to be more least-priviledge-y

  count = local.bastion_config.enable_bastion_terraform_permissions ? 1 : 0

  name   = "${local.bastion_config.name}-terraform-policy"
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
                "inspector:UpdateAssessmentTarget",
                "secretsmanager:GetSecretValue"
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
                "aws-portal:*Billing"
            ],
            "Resource": "*",
            "Effect": "Deny"
        }
    ]
}
EOF
  tags   = local.bastion_config.tags
}

locals {
  name                = basename(path.cwd)
  eks_oidc_issuer_url = replace(var.eks_oidc_provider_arn, "/^(.*provider/)/", "")
}

data "aws_iam_policy_document" "sops" {

  statement {
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey", "kms:GenerateRandom"]
    resources = [aws_kms_key.sops.arn]
  }
  statement {
    actions   = ["kms:GenerateRandom"]
    resources = ["*"]
  }
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [var.vpc_id]
    }
  }
}

resource "aws_kms_key" "sops" {
  enable_key_rotation     = true
  description             = "KMS key is used to encrypt / decrypt sops files in git"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "a" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.sops.key_id
}

resource "aws_iam_policy" "sops_policy" {
  description = "IAM Policy for sops encrypting & decrypting git secrets"
  name_prefix = "${var.cluster_name}-${var.policy_name_prefix}"
  policy      = data.aws_iam_policy_document.sops.json
}

resource "aws_iam_role" "irsa_sops" {
  count = var.sops_iam_policies != null ? 1 : 0

  name        = try(coalesce(var.irsa_sops_iam_role_name, format("%s-%s-%s", var.cluster_name, trim(var.kubernetes_service_account, "-*"), "irsa")), null)
  description = "AWS IAM Role for the Kubernetes service account ${var.kubernetes_service_account}."
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : var.eks_oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${local.eks_oidc_issuer_url}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}",
            "${local.eks_oidc_issuer_url}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  path                  = var.irsa_iam_role_path
  force_detach_policies = true
  permissions_boundary  = var.irsa_iam_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {

  policy_arn = aws_iam_policy.sops_policy.arn
  role       = aws_iam_role.irsa_sops[0].name
}

resource "aws_iam_role_policy_attachment" "sops" {
  role       = var.role_name
  policy_arn = aws_iam_policy.sops_policy.arn
}

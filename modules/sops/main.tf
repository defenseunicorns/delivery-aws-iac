locals {
  eks_oidc_issuer_url = replace(var.eks_oidc_provider_arn, "/^(.*provider/)/", "")
}

data "aws_kms_key" "default" {
  key_id = var.kms_key_arn
}

data "aws_iam_policy_document" "sops" {

  statement {
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey", "kms:GenerateRandom"]
    resources = [data.aws_kms_key.default.arn]
  }
  statement {
    actions   = ["kms:GenerateRandom"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sops_policy" {
  description = "IAM Policy for sops encrypting & decrypting git secrets"
  name_prefix = var.policy_name_prefix
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

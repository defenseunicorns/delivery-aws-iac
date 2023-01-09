data "aws_caller_identity" "current" {}

module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.3"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_key_path
  generate_ssh_key    = var.generate_ssh_key

  context = module.this.context
}

module "ec2_bastion" {
  source = "git::https://github.com/cloudposse/terraform-aws-ec2-bastion-server.git?ref=0.30.1"

  ami                         = var.ami
  instance_type               = var.instance_type
  subnets                     = var.private_subnet_ids
  key_name                    = module.aws_key_pair.key_name
  user_data                   = var.user_data
  vpc_id                      = var.vpc_id
  associate_public_ip_address = var.associate_public_ip_address

  context = module.this.context
}

resource "aws_iam_role_policy_attachment" "sops" {
  count      = var.add_sops_policy ? 1 : 0
  role       = module.ec2_bastion.role
  policy_arn = var.cluster_sops_policy_arn
}

data "aws_iam_policy_document" "bastion_ssh_access_via_ssm" {
  statement {

    actions = ["ssm:StartSession"]

    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${module.ec2_bastion.instance_id}",
      "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
    ]
  }
}

resource "aws_iam_policy" "bastion_ssh_access_via_ssm" {
  name        = "ssh-policy"

  policy = data.aws_iam_policy_document.bastion_ssh_access_via_ssm.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssh" {
  role   = module.ec2_bastion.role
  policy_arn = aws_iam_policy.bastion_ssh_access_via_ssm.arn
}

# resource "aws_iam_role" "bastion_ssh_access_via_ssm" {
#   name                 = "${var.name}-auth-ssh-role"
#   description          = "EKS AuthConfig Role"
#   assume_role_policy    = data.aws_iam_policy_document.bastion_ssh_access_via_ssm.json
#   path                  = "/"
#   force_detach_policies = true
#   managed_policy_arns = ["arn:aws:iam::aws:policy/AWS-StartSSHSession"]

#   tags = local.tags
# }
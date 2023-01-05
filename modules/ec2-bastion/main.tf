module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.0"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_key_path
  generate_ssh_key    = var.generate_ssh_key
}

module "ec2_bastion" {
  source = "git::https://github.com/cloudposse/terraform-aws-ec2-bastion-server.git?ref=tags/0.27.0"

  ami                         = var.ami
  instance_type               = var.instance_type
  security_group_enabled      = false
  subnets                     = var.private_subnet_ids
  key_name                    = module.aws_key_pair.key_name
  user_data                   = var.user_data
  vpc_id                      = var.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
}

resource "aws_iam_role_policy_attachment" "sops" {
  count      = var.add_sops_policy ? 1 : 0
  role       = aws_iam_role.default[0].name
  policy_arn = var.cluster_sops_policy_arn
}
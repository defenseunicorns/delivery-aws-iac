module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.0"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_key_path
  generate_ssh_key    = var.generate_ssh_key
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
}

resource "aws_iam_role_policy_attachment" "sops" {
  count      = var.add_sops_policy ? 1 : 0
  role       = module.ec2_bastion.role[0]
  policy_arn = var.cluster_sops_policy_arn
}
#wsus instance

locals {
  common_tags = {
    Name        = "wsus"
    Environment = var.envname
    Service     = var.envtype
  }
}

resource "aws_instance" "wsus" {
  #checkov:skip=CKV_AWS_126: Not using aws detailed monitoring at this time
  #checkov:skip=CKV_AWS_79: Dependency on metadata service for bootstrap
  #checkov:skip=CKV2_AWS_17: EC2 does blong to a VPC via subnet parameter 
  ami                     = var.ami
  instance_type           = var.instance_type
  user_data               = "<powershell>${data.template_file.additional_drive.rendered}${data.template_file.wsus_domain_connect_userdata.rendered}${data.template_file.wsus.rendered}${var.userdata}</powershell><persist>true</persist>"
  subnet_id               = var.subnet_id
  iam_instance_profile    = var.instance_profile
  vpc_security_group_ids  = flatten([var.vpc_security_group_ids, aws_security_group.wsus.id])
  disable_api_termination = false
  key_name                = var.key_name
  ebs_optimized           = true

  tags = merge(
    local.common_tags,
    var.additional_tags
  )

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }
  lifecycle {
    ignore_changes = [tags, root_block_device[0].tags]
  }
}

resource "aws_ebs_volume" "wsus_volumes" {
  #checkov:skip=CKV2_AWS_9: Our EBS volumes get automated backups through another module
  count = length(var.extra_ebs_blocks)

  availability_zone = aws_instance.wsus.availability_zone
  encrypted         = true
  size              = var.extra_ebs_blocks[count.index].volume_size
  type              = var.extra_ebs_blocks[count.index].volume_type

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_volume_attachment" "wsus_ebs_att" {
  count = length(var.extra_ebs_blocks)

  device_name = var.extra_ebs_blocks[count.index].device_name
  volume_id   = aws_ebs_volume.wsus_volumes[count.index].id
  instance_id = aws_instance.wsus.id
}

#wsus security group

resource "aws_security_group" "wsus" {
  name        = "wsus"
  vpc_id      = var.vpc_id
  description = "wsus security group"

  tags = {
    Name = coalesce(var.sg_name_overide, "${var.customer}-${var.envname}-wsus")
  }
}

resource "aws_security_group_rule" "wsus_in" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8530
  to_port           = 8531
  security_group_id = aws_security_group.wsus.id
  cidr_blocks       = var.wu_inbound_cidrs
}

resource "aws_security_group_rule" "windows_update_80" {
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.wsus.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "windows_update_443" {
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.wsus.id
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  role_name               = "${var.name}-role"
  bucket_prefix           = var.name

  # ssh access
  keys_update_frequency      = "*/5 * * * *"
  enable_hourly_cron_updates = true

  security_group_configs = [{
    name        = "${var.name}-sg"
    description = "SG for ${var.name}"
    vpc_id      = var.vpc_id
    ingress_rules = [{
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_public_ips # admin IPs or private IP (internal) of Software Defined Perimter
      },
    ]
    egress_rules = [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }]
  }]

  # instance
  instance_type           = "t3a.small"
  root_volume_config = {
    volume_type = "gp3"
    volume_size = "20"
    encrypted   = true
  }
}
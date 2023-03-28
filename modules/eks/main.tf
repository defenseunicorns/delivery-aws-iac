#---------------------------------------------------------------
# EKS Blueprints
#---------------------------------------------------------------

module "aws_eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v19.10.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  # public_subnet_ids  = var.public_subnet_ids
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  self_managed_node_group_defaults = var.self_managed_node_group_defaults
  self_managed_node_groups         = var.self_managed_node_groups
  eks_managed_node_groups          = var.eks_managed_node_groups

  cluster_addons = local.cluster_addons

  #----------------------------------------------------------------------------------------------------------#
  # Security groups used in this module created by the upstream modules terraform-aws-eks (https://github.com/terraform-aws-modules/terraform-aws-eks).
  #   Upstream module implemented Security groups based on the best practices doc https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html.
  #   So, by default the security groups are restrictive. Users needs to enable rules for specific ports required for App requirement or Add-ons
  #   See the notes below for each rule used in these examples
  #----------------------------------------------------------------------------------------------------------#
  cluster_security_group_additional_rules = {
    ingress_bastion_to_cluster = {
      # name        = "allow bastion ingress to cluster"
      description              = "Bastion SG to Cluster"
      security_group_id        = module.aws_eks.cluster_security_group_id
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      type                     = "ingress"
      source_security_group_id = var.source_security_group_id
    }
  }

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  create_aws_auth_configmap = local.create_aws_auth_configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap

  kms_key_administrators = distinct(concat(local.admin_arns, var.kms_key_administrators))
  aws_auth_users         = distinct(concat(local.aws_auth_users, var.aws_auth_users))
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.auth_eks_role.arn
      username = aws_iam_role.auth_eks_role.name
      groups   = ["system:masters"]
    },
    {
      rolearn  = var.bastion_role_arn
      username = var.bastion_role_name
      groups   = ["system:masters"]
    }
  ]
}


resource "aws_iam_role" "auth_eks_role" {
  name               = "${var.name}-auth-eks-role"
  description        = "EKS AuthConfig Role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
              "AWS": ${length(local.admin_arns) == 0 ? "[]" : jsonencode(local.admin_arns)}
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

}

resource "kubernetes_storage_class_v1" "efs" {
  count = var.enable_efs ? 1 : 0
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap" # Dynamic provisioning
    fileSystemId     = module.efs[0].id
    directoryPerms   = "700"
  }

  mount_options = [
    "iam"
  ]

  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]
}

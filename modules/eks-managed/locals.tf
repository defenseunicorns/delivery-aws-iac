locals {
  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, var.name)

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = var.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

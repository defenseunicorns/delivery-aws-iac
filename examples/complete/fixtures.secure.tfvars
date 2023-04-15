region                         = "us-east-2"
region2                        = "us-east-1"
secondary_cidr_blocks          = ["100.64.0.0/16"] #https://aws.amazon.com/blogs/containers/optimize-ip-addresses-usage-by-pods-in-your-amazon-eks-cluster/
enable_eks_managed_nodegroups  = false
enable_self_managed_nodegroups = true
bastion_tenancy                = "dedicated"
eks_worker_tenancy             = "dedicated"
cluster_endpoint_public_access = false

create_aws_auth_configmap = true #secure example assumes enable_eks_managed_nodegroups = false, need to creaste the configmap ourselves

enable_eks_managed_nodegroups  = false
enable_self_managed_nodegroups = true
bastion_tenancy                = "dedicated"
eks_worker_tenancy             = "dedicated"
cluster_endpoint_public_access = false
create_kubernetes_resources    = false # terraform won't have access to the eks cluster due to public endpoint access being disabled

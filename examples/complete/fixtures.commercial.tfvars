enable_eks_managed_nodegroups  = true
enable_self_managed_nodegroups = true
eks_worker_tenancy             = "default"
cluster_endpoint_public_access = true

enable_bastion = true # you can turn this off if not using the go testing utilities

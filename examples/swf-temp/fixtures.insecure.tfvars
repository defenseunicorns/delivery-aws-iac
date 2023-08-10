create_aws_auth_configmap = true #need to creaste the configmap ourselves if not using managed nodes

enable_eks_managed_nodegroups  = true
enable_self_managed_nodegroups = true
bastion_tenancy                = "default"
eks_worker_tenancy             = "default"
cluster_endpoint_public_access = true

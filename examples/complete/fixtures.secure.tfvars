enable_managed_nodegroups = false
bastion_tenancy           = "dedicated"
eks_worker_tenancy        = "dedicated"
# cluster_endpoint_public_access is defined separately. We want the value to be false but need it to start out as true
# so that the cluster can be created. Once the cluster is created, we can set it to false and run terraform apply again
# to update the cluster.
#cluster_endpoint_public_access = false

# This code is used to validate that PVCs backed by EFS are working as expected. None of it is needed in production.

resource "kubernetes_persistent_volume_claim_v1" "test_claim" {
  count = var.enable_amazon_eks_aws_efs_csi_driver ? 1 : 0
  metadata {
    name      = "test-claim"
    namespace = "default"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        # Since EFS is the backing storage, the size of the PVC doesn't matter. EFS will grow as needed. But, K8s isn't happy if this value isn't set.
        storage = "1Mi"
      }
    }
    storage_class_name = module.eks.efs_storageclass_name
  }
}

resource "kubernetes_job_v1" "test_write" {
  # checkov:skip=CKV_K8S_21: "The default namespace should not be used" -- This is test code, not production
  count = var.enable_amazon_eks_aws_efs_csi_driver ? 1 : 0
  metadata {
    name      = "test-write"
    namespace = "default"
  }
  spec {
    template {
      metadata {
        name = "test-write"
      }
      spec {
        container {
          name    = "test-write"
          image   = "ubuntu:latest"
          command = ["dd", "if=/dev/zero", "of=/mnt/pv/test.img", "bs=1G", "count=1", "oflag=dsync"]
          volume_mount {
            mount_path = "/mnt/pv"
            name       = "test-write-volume"
          }
        }
        volume {
          name = "test-write-volume"
          persistent_volume_claim {
            claim_name = "test-claim"
          }
        }
        restart_policy = "Never"
      }
    }
  }
  depends_on = [kubernetes_persistent_volume_claim_v1.test_claim]
}

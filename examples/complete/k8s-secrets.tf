# This code is meant as an example of how one may be able to add secrets to their EKS cluster after it is created.

resource "kubernetes_namespace" "iac" {
  metadata {
    name = "iac"
  }
}

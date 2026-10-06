resource "helm_release" "gke_resources" {
  provider = helm.gke

  name       = "gke-resources"
  namespace  = "default"
  chart      = "${path.module}/helm-gke"

  depends_on = [
    google_container_cluster.primary
  ]
}

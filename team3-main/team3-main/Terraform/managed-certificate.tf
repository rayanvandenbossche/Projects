# resource "kubernetes_manifest" "managed_certificate" {
# 
#   manifest = {
#     apiVersion = "networking.gke.io/v1"
#     kind       = "ManagedCertificate"
#     metadata = {
#       name      = "managed-cert"
#       namespace = "default"
#     }
#     spec = {
#       domains = [
#         "team3.techtitans.be",
#         "www.team3.techtitans.be"
#       ]
#     }
#   }
# 
#   computed_fields = ["metadata.name"]
# 
#   depends_on = [
#     google_container_cluster.primary,
#     google_container_node_pool.primary_preemptible_nodes,
#     null_resource.gke_kubeconfig
#   ]
# }
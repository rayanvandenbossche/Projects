# resource "kubernetes_manifest" "frontend_config" {
#   manifest = {
#     apiVersion = "networking.gke.io/v1"
#     kind       = "FrontendConfig"
#     metadata = {
#       name      = "redirect-to-https"
#       namespace = "default"
#     }
#     spec = {
#       redirectToHttps = {
#         enabled          = true
#         responseCodeName = "PERMANENT_REDIRECT"
#       }
#     }
#   }
# 
#   depends_on = [
#     google_container_cluster.primary,
#     null_resource.gke_kubeconfig
#   ]
# }

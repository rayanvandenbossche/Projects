# resource "kubernetes_ingress_v1" "gce_ingress_https" {
#   metadata {
#     name      = "managed-cert-ingress"
#     namespace = "default"
# 
#     annotations = {
#       "kubernetes.io/ingress.class"                 = "gce"
#       "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.ingress_ip.name
#       "networking.gke.io/managed-certificates"      = "managed-cert"
#       "networking.gke.io/v1beta1.FrontendConfig"    = "redirect-to-https"
#     }
#   }
# 
#   spec {
#     default_backend {
#       service {
#         name = kubernetes_service.ai_player_service.metadata[0].name
#         port {
#           number = 80
#         }
#       }
#     }
#   }
# 
#   depends_on = [
#     kubernetes_manifest.https_redirect
#   ]
# }

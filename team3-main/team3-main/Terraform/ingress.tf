resource "kubernetes_ingress_v1" "gce_ingress" {
  metadata {
    name      = "managed-cert-ingress"

    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.ingress_ip.name
      "networking.gke.io/managed-certificates"      = "managed-cert"
      "networking.gke.io/frontend-config"           = "redirect-to-https"
    }
  }

  spec {
    ingress_class_name = "gce"

    # 🔹 ai-player.team3.techtitans.be
    rule {
      host = "ai-player.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "ai-player"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 www.ai-player.team3.techtitans.be
    rule {
      host = "www.ai-player.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "ai-player"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 metabase.team3.techtitans.be
    rule {
      host = "metabase.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "metabase"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 www.metabase.team3.techtitans.be
    rule {
      host = "www.metabase.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "metabase"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 ai-chatbot.team3.techtitans.be
    rule {
      host = "ai-chatbot.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "ai-chatbot"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 www.ai-chatbot.team3.techtitans.be
    rule {
      host = "www.ai-chatbot.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "ai-chatbot"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 recommendation.team3.techtitans.be
    rule {
      host = "recommendation.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "rec-api"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 www.recommendation.team3.techtitans.be
    rule {
      host = "www.recommendation.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "rec-api"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # 🔹 rabbitmq.team3.techtitans.be
    rule {
      host = "rabbitmq.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "rabbitmq-management"
              port {
                number = 15672
              }
            }
          }
        }
      }
    }

    # 🔹 www.rabbitmq.team3.techtitans.be
    rule {
      host = "www.rabbitmq.team3.techtitans.be"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "rabbitmq-management"
              port {
                number = 15672
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    helm_release.gke_resources,
    kubernetes_service.ai_player,
    kubernetes_service.metabase,
    kubernetes_service.ai_chatbot,
    kubernetes_service.rec_api
  ]
}

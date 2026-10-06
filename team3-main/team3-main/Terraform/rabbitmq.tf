resource "kubernetes_persistent_volume_claim" "rabbitmq_data" {
  metadata {
    name = "rabbitmq-data"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    name = "rabbitmq"
    labels = { app = "rabbitmq" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "rabbitmq" }
    }

    template {
      metadata {
        labels = { app = "rabbitmq" }
      }

      spec {
        container {
          name  = "rabbitmq"
          image = "rabbitmq:3-management"

          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = "guest"
          }
          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = "guest"
          }

          port { container_port = 5672 }
          port { container_port = 15672 }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/rabbitmq"
          }

          liveness_probe {
            exec {
              command = ["rabbitmq-diagnostics", "check_running"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.rabbitmq_data.metadata[0].name
          }
        }
      }
    }
  }
}

# resource "kubernetes_service" "rabbitmq" {
#   metadata {
#     name = "rabbitmq"
#   }
# 
#   spec {
#     selector = { app = "rabbitmq" }
# 
#     port {
#       name = "amqp"
#       port = 5672
#     }
# 
#     port {
#       name = "management"
#       port = 15672
#     }
# 
#     type = "NodePort"
#   }
#   depends_on = [
#     kubernetes_deployment.rabbitmq
#   ]
# }

resource "kubernetes_service" "rabbitmq_management" {
  metadata {
    name = "rabbitmq-management"
  }

  spec {
    selector = { app = "rabbitmq" }

    port {
      name        = "http"
      port        = 15672
      target_port = 15672
    }

    type = "NodePort"
  }
  depends_on = [
    kubernetes_deployment.rabbitmq
  ]
}

resource "kubernetes_service" "rabbitmq_amqp" {
  metadata {
    name = "rabbitmq-amqp"
  }

  spec {
    selector = { app = "rabbitmq" }

    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
    }

    type = "LoadBalancer"
    load_balancer_ip = google_compute_address.rabbitmq_ip.address
  }
  depends_on = [
    google_compute_address.rabbitmq_ip,
    kubernetes_deployment.rabbitmq
  ]
}

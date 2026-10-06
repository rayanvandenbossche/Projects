# PVC voor Ollama models (persistent storage)
resource "kubernetes_persistent_volume_claim" "ollama_data" {
  metadata {
    name = "ollama-data"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "ollama" {
  metadata {
    name      = "ollama"
    namespace = "default"
    labels = {
      app = "ollama"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ollama"
      }
    }

    template {
      metadata {
        labels = {
          app = "ollama"
        }
      }

      spec {
        init_container {
          name  = "pull-models"
          image = "ollama/ollama:latest"

          command = ["/bin/sh", "-c"]
          # We zetten alles op één regel met ; om CRLF problemen te voorkomen
          args = [
            "ollama serve & sleep 15; echo 'Pulling nomic...'; ollama pull nomic-embed-text; echo 'Pulling gemma...'; ollama pull gemma3:4b; pkill ollama; sleep 5"
          ]

          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }

          resources {
            requests = {
              memory = "2Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "8Gi"
              cpu    = "2000m"
            }
          }
        }

        container {
          name  = "ollama"
          image = "ollama/ollama:latest"

          port {
            container_port = 11434
            name           = "http"
          }

          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }

          resources {
            requests = {
              memory = "2Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "8Gi"
              cpu    = "2000m"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 11434
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 11434
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }

        volume {
          name = "ollama-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ollama_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.ollama_data
  ]
}

resource "kubernetes_service" "ollama" {
  metadata {
    name = "ollama"
  }

  spec {
    selector = {
      app = "ollama"
    }

    port {
      port        = 11434
      target_port = 11434
      name        = "http"
    }

    type = "ClusterIP"
  }

  depends_on = [
    kubernetes_deployment.ollama
  ]
}
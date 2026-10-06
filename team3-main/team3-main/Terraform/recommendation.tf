resource "kubernetes_deployment" "rec_api" {
  metadata {
    name = "rec-api"
    labels = { app = "rec-api" }
    annotations = {
      # Vertel Keel om deze deployment te beheren
      "keel.sh/policy" = "force"
      # Gebruik 'poll' omdat we de registry scannen (om de 5 min)
      "keel.sh/trigger" = "poll"
      # Het tijdschema
      "keel.sh/pollSchedule" = "@every 5m"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "rec-api" }
    }

    template {
      metadata {
        labels = { app = "rec-api" }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry_recommendation.metadata[0].name
        }

        container {
          name  = "rec-api"
          image = var.image_recommendation
          image_pull_policy = "Always"

          env {
            name  = "DATABASE_URL"
            value = "postgresql://user:password@rec-db:5432/recommendations_db"
          }

          env {
            name  = "RABBITMQ_HOST"
            value = "rabbitmq"
          }

          env {
            name  = "RABBITMQ_PORT"
            value = "5672"
          }

          port {
            container_port = 8800
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rec_api" {
  metadata {
    name = "rec-api"
    annotations = {
      "cloud.google.com/backend-config" = jsonencode({
        ports = {
          http = "rec-api-backend-config"
        }
      })
    }
  }

  spec {
    selector = { app = "rec-api" }

    port {
      name        = "http"
      port        = 80
      target_port = 8800
    }

    type = "NodePort"
  }

  depends_on = [
    kubernetes_deployment.rec_api,
    kubectl_manifest.rec_api_backend_config
  ]
}

resource "kubectl_manifest" "rec_api_backend_config" {
  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "rec-api-backend-config"
      namespace = "default"
    }
    spec = {
      timeoutSec = 300
      healthCheck = {
        type        = "HTTP"
        requestPath = "/health"
      }
    }
  })

  depends_on = [
    google_container_cluster.primary
  ]
}
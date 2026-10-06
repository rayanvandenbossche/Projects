resource "kubectl_manifest" "ai_chatbot_secrets" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "ai-chatbot-secrets"
      namespace = "default"
    }
    type = "Opaque"
    data = {
      GEMINI_API_KEY  = base64encode(var.gemini_api_key)
      API_KEY_IAO_7   = base64encode(var.api_key_iao_7)
      API_KEY_IAO_11  = base64encode(var.api_key_iao_11)
      API_KEY_IAO_15  = base64encode(var.api_key_iao_15)
      API_KEY_IAO_19  = base64encode(var.api_key_iao_19)
      API_KEY_IAO_22  = base64encode(var.api_key_iao_22)
      API_KEY_AI_TEAM = base64encode(var.api_key_ai_team)
    }
  })

  depends_on = [
    google_container_cluster.primary
  ]
}


resource "kubernetes_deployment" "ai_chatbot" {
  metadata {
    name      = "ai-chatbot"
    namespace = "default"
    labels = {
      app = "ai-chatbot"
    }
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
      match_labels = {
        app = "ai-chatbot"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai-chatbot"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry_chatbot.metadata[0].name
        }

        container {
          name  = "ai-chatbot"
          image = var.image_ai_chatbot
          image_pull_policy = "Always"

          port {
            container_port = 8000
          }

          env_from {
            secret_ref {
              name = "ai-chatbot-secrets"
            }
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql+psycopg2://aiuser:aipassword@postgres-chatbot:5432/aichatbot"
          }

          env {
            name  = "OLLAMA_BASE_URL"
            value = "http://ollama:11434"
          }
          
          env {
            name = "REC_SERVICE_URL_PROD"
            value = "https://www.recommendation.team3.techtitans.be"
          }

        }
      }
    }
  }
  depends_on = [
    google_container_cluster.primary,
    kubernetes_secret.gitlab_registry_chatbot,
    kubernetes_service.postgres_chatbot
  ]
}

resource "kubernetes_service" "ai_chatbot" {
  metadata {
    name = "ai-chatbot"
    annotations = {
      "cloud.google.com/backend-config" = jsonencode({
        "ports" = {
          "http" = "ollama-backend-config"
        }
      })
    }
  }

  spec {
    selector = {
      app = "ai-chatbot"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8000
    }

    type = "NodePort"
  }

  depends_on = [
    kubernetes_deployment.ai_chatbot,
    kubectl_manifest.ollama_backend_config
  ]
}
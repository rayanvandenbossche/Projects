resource "kubernetes_deployment" "ai_player" {
  metadata {
    name = "ai-player"
    labels = {
      app = "ai-player"
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
        app = "ai-player"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai-player"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry_player.metadata[0].name
        }
        container {
          image = var.image_ai_player
          name  = "ai-player"
          image_pull_policy = "Always"

          port {
            container_port = 8000
            protocol       = "TCP"
          }

          # 🔗 DB connectie
          env {
            name  = "DATABASE_URL"
            value = "postgresql://user:password@postgres-player:5432/ai_db"
          }
        }
      }
    }
  }
  depends_on = [
    google_container_cluster.primary,
    kubernetes_secret.gitlab_registry_player,
    kubernetes_service.postgres_player
  ]
}

resource "kubernetes_service" "ai_player" {
  metadata {
    name = "ai-player"
  }

  spec {
    selector = {
      app = "ai-player"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "NodePort"
  }
  depends_on = [
    kubernetes_deployment.ai_player
  ]
}

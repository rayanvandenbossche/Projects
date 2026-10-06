resource "kubernetes_horizontal_pod_autoscaler_v2" "ai_player" {
  metadata {
    name = "ai-player-hpa"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.ai_player.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    behavior {
      scale_up {
        select_policy = "Max"
        stabilization_window_seconds = 0

        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 30
        }
      }

      scale_down {
        select_policy = "Max"
        stabilization_window_seconds = 300

        policy {
          type           = "Percent"
          value          = 50
          period_seconds = 60
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.ai_player]
}

resource "kubernetes_deployment" "metabase" {
  metadata {
    name = "metabase"
    labels = {
      app = "metabase"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "metabase"
      }
    }

    template {
      metadata {
        labels = {
          app = "metabase"
        }
      }

      spec {
        container {
          name  = "metabase"
          image = "metabase/metabase:latest"

          port {
            container_port = 3000
          }
        }
      }
    }
  }
  depends_on = [
    google_container_cluster.primary,
    kubernetes_service.postgres_player
  ]
}

resource "kubernetes_service" "metabase" {
  metadata {
    name = "metabase"
  }

  spec {
    selector = {
      app = "metabase"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "NodePort"
  }
  depends_on = [
    kubernetes_deployment.metabase
  ]
}

resource "kubernetes_persistent_volume_claim" "postgres_player_data" {
  metadata {
    name = "postgres-player-data"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "postgres_player" {
  metadata {
    name = "postgres-player"
    labels = {
      app = "postgres-player"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-player"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-player"
        }
      }

      spec {
        # 🔑 VERPLICHT voor Postgres + PVC in GKE
        security_context {
          fs_group = 999
        }

        container {
          name  = "postgres"
          image = "postgres:15"

          # 🔑 Postgres draait als juiste user
          security_context {
            run_as_user = 999
          }

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value = "user"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          env {
            name  = "POSTGRES_DB"
            value = "ai_db"
          }

          # 🔑 CRUCIALE FIX (lost+found vermijden)
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data"
          }

          # 👇 Mount PVC op hoger niveau
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql"
          }
        }

        # 👇 PVC koppelen
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_player_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    google_container_cluster.primary,
    kubernetes_persistent_volume_claim.postgres_player_data
  ]
}


resource "kubernetes_service" "postgres_player" {
  metadata {
    name = "postgres-player"
  }

  spec {
    selector = {
      app = "postgres-player"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.postgres_ip.address
  }

  depends_on = [
    kubernetes_deployment.postgres_player,
    google_compute_address.postgres_ip
  ]
}
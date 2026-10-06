resource "kubernetes_persistent_volume_claim" "rec_db_data" {
  metadata {
    name = "rec-db-data"
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

resource "kubernetes_deployment" "rec_db" {
  metadata {
    name   = "rec-db"
    labels = { app = "rec-db" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "rec-db" }
    }

    template {
      metadata {
        labels = { app = "rec-db" }
      }

      spec {
        # 🔑 VERPLICHT voor Postgres + PVC in GKE
        security_context {
          fs_group = 999
        }

        container {
          name  = "postgres"
          image = "postgres:15"

          # 🔑 Postgres user
          security_context {
            run_as_user = 999
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
            value = "recommendations_db"
          }

          # 🔑 CRUCIALE FIX (lost+found vermijden)
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data"
          }

          port {
            container_port = 5432
          }

          # 👇 Mount PVC op hoger niveau
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql"
          }
        }

        # 👇 PVC koppelen
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.rec_db_data.metadata[0].name
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "rec_db" {
  metadata {
    name = "rec-db"
  }

  spec {
    selector = { app = "rec-db" }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_deployment.rec_db
  ]
}

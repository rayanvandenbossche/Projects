resource "kubernetes_persistent_volume_claim" "postgres_chatbot_data" {
  metadata {
    name = "postgres-chatbot-data"
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

# ConfigMap met database init script
resource "kubernetes_config_map" "postgres_init_script" {
  metadata {
    name      = "postgres-init-script"
    namespace = "default"
  }

  data = {
    "init.sql" = <<-EOT
      DROP TABLE IF EXISTS knowledge;
      DROP TABLE IF EXISTS chat_cache;

      CREATE TABLE IF NOT EXISTS knowledge
      (
          id        SERIAL PRIMARY KEY,
          source    VARCHAR(255),
          content   TEXT,
          metadata  TEXT,
          embedding FLOAT8[]
      );

      CREATE TABLE IF NOT EXISTS chat_cache
      (
          id                  SERIAL PRIMARY KEY,
          normalized_question TEXT NOT NULL,
          original_question   TEXT NOT NULL,
          game_name           VARCHAR(255),
          team_number         INTEGER,
          answer              TEXT NOT NULL,
          sources             JSONB,
          embedding           FLOAT8[]
      );

      CREATE UNIQUE INDEX IF NOT EXISTS uniq_chat_cache_entry
          ON chat_cache (normalized_question, game_name, team_number);
    EOT
  }
}


# PostgreSQL Deployment met init script
resource "kubernetes_deployment" "postgres_chatbot" {
  metadata {
    name = "postgres-chatbot"
    labels = {
      app = "postgres-chatbot"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-chatbot"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-chatbot"
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

          # 🔑 Postgres user
          security_context {
            run_as_user = 999
          }

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value = "aiuser"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "aipassword"
          }

          env {
            name  = "POSTGRES_DB"
            value = "aichatbot"
          }

          # 🔑 DE CRUCIALE FIX (lost+found probleem)
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data"
          }

          # Init SQL (loopt alleen bij lege database)
          volume_mount {
            name       = "init-script"
            mount_path = "/docker-entrypoint-initdb.d"
            read_only  = true
          }

          # 👇 Mount PVC op HOGER niveau
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql"
          }
        }

        # Init SQL volume
        volume {
          name = "init-script"
          config_map {
            name = kubernetes_config_map.postgres_init_script.metadata[0].name
          }
        }

        # PVC volume
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_chatbot_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    google_container_cluster.primary,
    kubernetes_config_map.postgres_init_script,
    kubernetes_persistent_volume_claim.postgres_chatbot_data
  ]
}


resource "kubernetes_service" "postgres_chatbot" {
  metadata {
    name = "postgres-chatbot"
  }

  spec {
    selector = {
      app = "postgres-chatbot"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_deployment.postgres_chatbot
  ]
}

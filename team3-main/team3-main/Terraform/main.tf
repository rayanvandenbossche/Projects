# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "ai-player-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1
}

# Autoscaling Node Pool
resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "ai-player-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"
    image_type   = "COS_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config[0].resource_labels,
      node_config[0].kubelet_config
    ]
  }
}

# Kubernetes Secrets for GitLab Registry
resource "kubernetes_secret" "gitlab_registry_player" {
  metadata {
    name = "gitlab-registry-player-auth"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          auth = base64encode("${var.gitlab_username_player}:${var.gitlab_token_player}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "gitlab_registry_chatbot" {
  metadata {
    name = "gitlab-registry-chatbot-auth"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          auth = base64encode("${var.gitlab_username_chatbot}:${var.gitlab_token_chatbot}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "gitlab_registry_ollama" {
  metadata {
    name = "gitlab-registry-ollama-auth"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          auth = base64encode("${var.gitlab_username_ollama}:${var.gitlab_token_ollama}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "gitlab_registry_recommendation" {
  metadata {
    name = "gitlab-registry-recommendation-auth"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          auth = base64encode("${var.gitlab_username_recommendation}:${var.gitlab_token_recommendation}")
        }
      }
    })
  }
}
resource "kubectl_manifest" "ollama_backend_config" {
  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "ollama-backend-config"
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
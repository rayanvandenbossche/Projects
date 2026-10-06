resource "helm_release" "keel" {
  provider   = helm.gke
  name       = "keel"
  repository = "https://charts.keel.sh"
  chart      = "keel"
  namespace  = "keel"

  create_namespace = true

  values = [
    yamlencode({
      image = {
        repository = "keelhq/keel"
        tag        = "0.19.1"
      }

      poll = {
        enabled = true
      }

      helm = {
        enabled = true
      }
    })
  ]

  timeout = 600
  wait    = true
  atomic  = true
}

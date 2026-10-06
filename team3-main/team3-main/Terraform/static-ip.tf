resource "google_compute_global_address" "ingress_ip" {
  name = "gke-managed-cert-ip"
}
resource "google_compute_address" "postgres_ip" {
  name   = "postgres-player-ip"
  region = var.region
}
resource "google_compute_address" "rabbitmq_ip" {
  name   = "rabbitmq"
  region = var.region
}

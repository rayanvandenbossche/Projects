output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Endpoint"
  sensitive   = true
}

output "ingress_ip_address" {
  value = google_compute_global_address.ingress_ip.address
}
output "postgres_player_external_ip" {
  value       = google_compute_address.postgres_ip.address
  description = "Static external IP for PostgreSQL"
}
output "rabbitmq_external_ip" {
  value       = google_compute_address.rabbitmq_ip.address
}
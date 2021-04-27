output "master_ip_addr" {
  value = google_container_cluster.primary.endpoint
}

output "reserved_ip_address" {
  value = google_compute_address.kubernetes_cluster.address
}

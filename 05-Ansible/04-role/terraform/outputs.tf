output "clickhouse-centos" {
  value       = yandex_compute_instance.centos[0].network_interface[0].nat_ip_address
}
output "vector-centos" {
  value       = yandex_compute_instance.centos[1].network_interface[0].nat_ip_address
}
output "lighthouse-ubuntu" {
  value       = yandex_compute_instance.ubuntu.network_interface[0].nat_ip_address
}
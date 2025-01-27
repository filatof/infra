#---------CONSUL CLUSTER
output "consul_ip" {#-------external address
  value = [for i in yandex_compute_instance.consul : i.network_interface[0].nat_ip_address]
}

#-------------gitlab----registry
output "gitlab_ip" {
  value = yandex_compute_instance.gitlab.network_interface.0.nat_ip_address
}
#-----------prometheus----grafana
output "prometheus_ip" {
  value = yandex_compute_instance.prometheus.network_interface.0.nat_ip_address
}

#---------------test instances
output "test_ip" {
  value = yandex_compute_instance.test.network_interface.0.nat_ip_address
}
#-------------Create inventory file
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [consul]
    ${join("\n", [for i in yandex_compute_instance.consul : i.network_interface[0].nat_ip_address])}

    [gitlab]
    ${yandex_compute_instance.gitlab.network_interface.0.ip_address}

    [prometheus]
    ${yandex_compute_instance.prometheus.network_interface.0.ip_address}

    [test]
    ${yandex_compute_instance.test.network_interface.0.ip_address}
  EOT
  filename = "${path.module}/../../../ansible/inventories/yandex.ini"
}
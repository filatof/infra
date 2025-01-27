#---------CONSUL CLUSTER
output "consul_int" {#-----internal address
  value = [for i in yandex_compute_instance.consul : i.network_interface[0].ip_address]
}

output "consul_out" {#-------external address
  value = [for i in yandex_compute_instance.consul : i.network_interface[0].nat_ip_address]
}


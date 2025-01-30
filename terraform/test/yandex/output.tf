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
  value = [for i in yandex_compute_instance.test : i.network_interface[0].nat_ip_address]
}
#-------------Create inventory file
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [consul_instances]
    %{for i, instance in yandex_compute_instance.consul~}
    ${format("server%d ansible_host=%s consul_bind_address=%s consul_client_address=\"%s 127.0.0.1\" consul_node_role=server consul_bootstrap_expect=true consul_acl_enable=true consul_version=1.20.2 ansible_user=fill ansible_port=2222\n", i + 1, instance.network_interface[0].nat_ip_address, instance.network_interface[0].nat_ip_address, instance.network_interface[0].nat_ip_address)}
    %{endfor~}
    ${format("gitlab ansible_host=%s consul_bind_address=%s consul_client_address=\"%s 127.0.0.1\" consul_node_role=client consul_enable_local_script_checks=true consul_acl_enable=true consul_version=1.20.2 ansible_user=fill ansible_port=2222\n", yandex_compute_instance.gitlab.network_interface[0].nat_ip_address, yandex_compute_instance.gitlab.network_interface[0].nat_ip_address, yandex_compute_instance.gitlab.network_interface[0].nat_ip_address)}
    ${format("prometheus ansible_host=%s consul_bind_address=%s consul_client_address=\"%s 127.0.0.1\" consul_node_role=client consul_enable_local_script_checks=true consul_acl_enable=true consul_version=1.20.2 ansible_user=fill ansible_port=2222\n", yandex_compute_instance.prometheus.network_interface[0].nat_ip_address, yandex_compute_instance.prometheus.network_interface[0].nat_ip_address, yandex_compute_instance.prometheus.network_interface[0].nat_ip_address)}
    %{for i, instance in yandex_compute_instance.test~}
    ${format("test-vm%d ansible_host=%s consul_bind_address=%s consul_client_address=\"%s 127.0.0.1\" consul_node_role=client consul_enable_local_script_checks=true consul_acl_enable=true consul_version=1.20.2 ansible_user=fill ansible_port=2222\n", i + 1, instance.network_interface[0].nat_ip_address, instance.network_interface[0].nat_ip_address, instance.network_interface[0].nat_ip_address)}
    %{endfor~}

    [gitlab]
    ${format("gitlab ansible_host=%s ansible_port=2222\n", yandex_compute_instance.gitlab.network_interface[0].nat_ip_address)}

    [monitoring]
    ${format("prometheus ansible_host=%s ansible_port=2222\n", yandex_compute_instance.prometheus.network_interface[0].nat_ip_address)}

    [test_vm]
    %{for i, instance in yandex_compute_instance.test~}
    ${format("test-vm%d ansible_host=%s ansible_port=2222\n", i + 1, instance.network_interface[0].nat_ip_address)}
    %{endfor~}
  EOT
  filename = "${path.module}/../../../ansible/inventories/yandex.ini"
}
output "consul" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.consul-vm) :
    format("consul-%02d", i + 1) => proxmox_virtual_environment_vm.consul[i].ipv4_addresses[1]
  }
}

output "prometheus" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.prometheus-vm) :
    format("prometheus-%02d", i + 1) => proxmox_virtual_environment_vm.prometheus[i].ipv4_addresses[1]
  }
}

output "gitlab" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.gitlab-vm) :
    format("gitlab-%02d", i + 1) => proxmox_virtual_environment_vm.prometheus[i].ipv4_addresses[1]
  }
}

output "node" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.test-vm) :
    format("node-%02d", i + 1) => proxmox_virtual_environment_vm.node[i].ipv4_addresses[1]
  }
}


#создаем файл инвентаря для ansible
resource "local_file" "ansible_inventory" {
  filename = "hosts"
  content = join("\n", concat(
    # Первые три сервера consul
    [for i in range(3) : format(
      "consul%d ansible_host=192.168.1.%d ansible_user=fill ansible_port=22 ansible_private_key_file=/Users/fill/.ssh/id_ed25519",
      i + 1,
      i + 51
    )],

    # Prometheus
    ["prometheus ansible_host=192.168.1.54 ansible_user=fill ansible_port=22 ansible_private_key_file=/Users/fill/.ssh/id_ed25519"],

    # GitLab
    ["gitlab ansible_host=192.168.1.55 ansible_user=fill ansible_port=22 ansible_private_key_file=/Users/fill/.ssh/id_ed25519"],

    # Две node
    [for i in range(2) : format(
      "node%d ansible_host=192.168.1.%d ansible_user=fill ansible_port=22 ansible_private_key_file=/Users/fill/.ssh/id_ed25519",
      i + 1,
      i + 56
    )]
  ))
}
output "consul" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(3) :
    format("consul-%02d", i + 1) => proxmox_virtual_environment_vm.consul[i].ipv4_addresses[1]
  }
}

output "prometheus" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(1) :
    format("consul-%02d", i + 1) => proxmox_virtual_environment_vm.prometheus[i].ipv4_addresses[1]
  }
}

output "node" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(4) :
    format("consul-%02d", i + 1) => proxmox_virtual_environment_vm.node[i].ipv4_addresses[1]
  }
}


#создаем файл инвентаря для ansible
resource "local_file" "ansible_inventory" {
  filename = "hosts"
  content = join("\n", [
    for i in range(8) : format(
      "%s ansible_host=192.168.1.%d ansible_user=fill ansible_port=22 ansible_private_key_file=/Users/fill/.ssh/id_ed25519",
      i < 3 ? "server${i + 1}" : "node${i - 2}", # Логика для имен
      i + 51                                     # Логика для IP-адресов
    )
  ])
}

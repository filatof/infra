output "prod" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.prod-vm) :
    format("consul-%02d", i + 1) => proxmox_virtual_environment_vm.node[i].ipv4_addresses[1]
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  count       = var.test-vm
  name        = format("node-%02d", count.index + 1)
  migrate     = true
  description = "Managed by OpenTofu"
  tags        = ["teststage"]
  on_boot     = true
  vm_id     = format("32%02d", count.index + 6)

  node_name = "pimox2"

  clone {
    vm_id     = "3007"
    retries   = 2
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 1
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = 1024
  }

  disk {
    size         = "20"
    interface    = "virtio0"
    datastore_id = "local"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "local"
    ip_config {
      ipv4 {
        #address = "dhcp"
        address = format("192.168.1.%d/24", count.index + 56)
        gateway = "192.168.1.1"
      }
    }
    dns {
      servers = [
        "192.168.1.1",
        "8.8.8.8"
      ]
    }
    user_account {
      username = "fill"
      keys = [
        var.ssh_public_key
      ]
    }
  }
}

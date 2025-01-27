resource "yandex_compute_image" "ubuntu_2004" {
  source_family = "ubuntu-2004-lts"
}

resource "yandex_compute_disk" "disk_consul" {
  count = var.consul
  name     = "boot-disk-${count.index + 1}"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "10"
  image_id = yandex_compute_image.ubuntu_2004.id
}

resource "yandex_compute_instance" "consul" {
  count = var.consul
  name = "consul${count.index + 1}"
  hostname = "consul${count.index + 1}"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.disk_consul[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.${40 + count.index + 1}"
    nat       = true
  }

  metadata = {
    user-data = "${file("user_data.yml")}"
    serial-port-enable     = "true"
    enable-monitoring-agent = "true"
  }

}

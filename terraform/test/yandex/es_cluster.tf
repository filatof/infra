resource "yandex_compute_image" "ubuntu_2004" {
  source_family = "ubuntu-2004-lts"
}

resource "yandex_compute_disk" "disk_es" {
  count = var.es
  name     = "boot-disk-${count.index + 1}"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "50"
  image_id = yandex_compute_image.ubuntu_2004.id
}

resource "yandex_compute_instance" "es" {
  count = var.es
  platform_id = "standard-v3"
  name = "consul${count.index + 1}"
  hostname = "consul${count.index + 1}"
  resources {
    cores         = 4
    memory        = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.disk_es[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.${50 + count.index + 1}"
    nat = count.index < 1 ? true : false  # Для первого белый ip для остальных серый
  }

  metadata = {
    user-data = "${file("user_data.yml")}"
    serial-port-enable     = "true"
    enable-monitoring-agent = "true"
  }

}

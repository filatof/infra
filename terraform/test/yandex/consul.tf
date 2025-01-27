resource "yandex_compute_image" "ubuntu_2004" {
  source_family = "ubuntu-2004-lts"
}

resource "yandex_compute_disk" "boot_disk" {
  count = 1
  name     = "boot-disk-${count.index + 1}"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "10"
  image_id = yandex_compute_image.ubuntu_2004.id
}

resource "yandex_compute_instance" "server" {
  count = 1
  name = "server${count.index + 1}"
  hostname = "server${count.index + 1}"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = file("metafile.yml")
    serial-port-enable     = "true"
    enable-monitoring-agent = "true"
  }

  service_account_id = "ajenq1pl8j49l4tr693g"
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_dns_zone" "zone_ru" {
  name        = "infrastruct-ru"
  description = "my dns"
  labels = {
    label1 = "lable_zone_dns_ru"
  }
  zone    = "infrastruct.online."
  public  = true
}

resource "yandex_dns_recordset" "record" {
  count = 1
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "server${count.index + 1}.infrastruct.online."
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.server[count.index].network_interface[0].nat_ip_address]
}

output "server_int" {
  value = [for i in yandex_compute_instance.server : i.network_interface[0].ip_address]
}

output "server_out" {
  value = [for i in yandex_compute_instance.server : i.network_interface[0].nat_ip_address]
}
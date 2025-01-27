#-----------диск для Prometheus
resource "yandex_compute_disk" "disk-prometheus" {
  name     = "disk-prometheus"
  type     = "network-hdd"
  size     = 10
  image_id = "fd87j6d92jlrbjqbl32q"
  labels = {
    environment = "label-prometheus"
  }
}

# инстанс для prometheus
resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  hostname = "prometheus"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.disk-prometheus.id
  }
  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.30"
    nat       = true
  }
  metadata = {
        user-data = "${file("user_data_prometheus.yml")}"
  }
}

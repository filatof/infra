#-----------диск для gitlab
resource "yandex_compute_disk" "disk-gitlab" {
  name     = "disk-gitlab"
  type     = "network-hdd"
  size     = 30
  image_id = "fd87j6d92jlrbjqbl32q"
  labels = {
    environment = "label-gitlab"
  }
}

#-----------инстанс для gitlab
resource "yandex_compute_instance" "gitlab" {
  name        = "gitlab"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  hostname = "gitlab"
  resources {
    cores         = 2
    memory        = 6
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.disk-gitlab.id
  }
  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.20"
    nat       = true
  }
  metadata = {
    user-data = "${file("user_data.yml")}"
  }
}

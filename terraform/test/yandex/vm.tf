
#----------------диск для test инстанса
resource "yandex_compute_disk" "disk-instance" {
  name     = "disk-instance"
  type     = "network-hdd"
  size     = 10
  image_id = "fd87j6d92jlrbjqbl32q"
  labels = {
    environment = "label-test-instance"
  }
}

#-------------инстанс для test
resource "yandex_compute_instance" "test" {
  name        = "test"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  hostname = "test"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.disk-instance.id
  }
  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.10"
    nat       = true
  }
  metadata = {
    user-data = "${file("user_data.yml")}"
  }
}










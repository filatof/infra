
#----------------диск для test инстанса
resource "yandex_compute_disk" "disk-instance" {
  count = var.vm_test
  name     = "disk-instance-${count.index + 1}"
  type     = "network-hdd"
  size     = 10
  image_id = "fd87j6d92jlrbjqbl32q"
  labels = {
    environment = "label-test-instance"
  }
}

#-------------инстанс для test
resource "yandex_compute_instance" "test" {
  count = var.vm_test
  name = "test-vm${count.index + 1}"
  hostname = "test-vm-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.disk-instance[count.index].id
  }
  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.subnet-a.id
    ip_address = "192.168.10.${10 + count.index + 1}"
    nat       = true
  }
  metadata = {
    user-data = "${file("user_data.yml")}"
  }
}










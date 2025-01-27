
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
    ip_address = "10.2.0.10"
    nat       = true
  }
  metadata = {
    user-data = "${file("user_data.yml")}"
  }
}

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
    ip_address = "10.2.0.20"
    nat       = true
  }
  metadata = {
    #ssh-keys = "fill:${file("~/.ssh/id_ed25519.pub")}"
    user-data = "${file("user_data.yml")}"
  }
}

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
    ip_address = "10.2.0.30"
    nat       = true
  }
  metadata = {
        user-data = "${file("user_data_prometheus.yml")}"
  }
}




resource "yandex_dns_recordset" "web" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.test.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "test" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "test.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.test.network_interface.0.nat_ip_address]
}





resource "yandex_dns_recordset" "prometheus" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "prometheus.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.prometheus.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "grafana" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "grafana.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.prometheus.network_interface.0.nat_ip_address]
}



output "test_ip" {
  value = yandex_compute_instance.test.network_interface.0.nat_ip_address
}

output "gitlab_ip" {
  value = yandex_compute_instance.gitlab.network_interface.0.nat_ip_address
}

output "prometheus_ip" {
  value = yandex_compute_instance.prometheus.network_interface.0.nat_ip_address
}
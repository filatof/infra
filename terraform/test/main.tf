terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  #---------загрузка файла состояний в s3-------------
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                   = "terraform.st"
    region                   = "ru-central1"
    key                      = "test-infra.serv"
    shared_credentials_files = ["di_storage.key"] #ссылка на ключ доступа к бакету

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true 
    skip_s3_checksum            = true 
  }
}

provider "yandex" { # все id  пердаем через файл variables.tf
  service_account_key_file = "di_key.json"
  cloud_id                 = var.cloud_id 
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}

#-------------определяем  сеть 
resource "yandex_vpc_network" "EQ-net" {
  name = "EQ-network"
}

#-----------оперделяем подсети в разных зонах 
resource "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.EQ-net.id
}

resource "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.EQ-net.id
}

#----------security group
resource "yandex_vpc_security_group" "EQ-sg" {
  name        = "EQ-security-group"
  description = "description for my security group"
  network_id  = yandex_vpc_network.EQ-net.id

  labels = {
    my-label = "sg-label"
  }

  dynamic "ingress" {
    for_each = ["80", "443","2222", "3000", "3100", "8080", "9090", "9080", "9093", "9095", "9100", "9113", "9104" ]
    content {
      protocol       = "TCP"
      description    = "rule1 description"
      v4_cidr_blocks = ["0.0.0.0/0"]
      from_port      = ingress.value
      to_port        = ingress.value
    }
  }

  egress {
    protocol       = "ANY"
    description    = "rule2 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

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


resource "yandex_dns_zone" "example_zone" {
  name        = "infrastruct"
  description = "my zone dns"
  labels = {
    label1 = "lable_zone_dns"
  }
  zone    = "infrastruct.ru."
  public  = true
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

resource "yandex_dns_recordset" "gitlab" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "gitlab.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.gitlab.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "registry" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "registry.gitlab.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.gitlab.network_interface.0.nat_ip_address]
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
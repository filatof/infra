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
    bucket                   = "test-tfstate-backet"
    region                   = "ru-central1"
    key                      = "gitlab.serv"
    shared_credentials_files = ["storage.key"] #ссылка на ключ доступа к бакету

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true 
    skip_s3_checksum            = true 
  }
}

provider "yandex" { # все id  пердаем через файл variables.tf
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id 
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}

#-------------определяем  сеть 
resource "yandex_vpc_network" "web-net" {
  name = "EQ-network"
}

#-----------оперделяем подсети в разных зонах 
resource "yandex_vpc_subnet" "subnet-a" {
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.web-net.id
}

resource "yandex_vpc_subnet" "subnet-b" {
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.web-net.id
}

#----------security group
resource "yandex_vpc_security_group" "group1" {
  name        = "my-security-group"
  description = "description for my security group"
  network_id  = yandex_vpc_network.web-net.id

  labels = {
    my-label = "my-label-value"
  }

  dynamic "ingress" {
    for_each = ["22", "80", "443","2222", "3000", "3100", "8080", "9090", "9080", "9093", "9095", "9100", "9113", "9104" ]
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

#-------------определяем группу серверов
resource "yandex_compute_instance_group" "web-group" {
  name                = "test-ig"
  service_account_id  = var.service_account_id
  deletion_protection = false
  instance_template {
    platform_id = "standard-v3"
    name         = "test-{instance.index}" # Присваиваем уникальное имя каждому инстансу в группе
    resources {
      memory        = 2
      cores         = 2
      core_fraction = 20
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        type     = "network-hdd"
        size = 10
        image_id = "fd87j6d92jlrbjqbl32q" #ubuntu 22.04
      }
    }
    network_interface {
      network_id = yandex_vpc_network.web-net.id
      subnet_ids = ["${yandex_vpc_subnet.subnet-a.id}", "${yandex_vpc_subnet.subnet-b.id}"]
      nat        = true
    }

    metadata = {
      #файл с ключами для доступа на сервер
      user-data = "${file("user_data_test.yml")}"
      #ssh-keys = "fill:${file("~/.ssh/id_ed25519.pub")}"
      #user-data = "${file("user_data.sh")}"

    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1 # пока будет один сервер
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 0
    max_deleting    = 1
  }

  load_balancer {
    target_group_name = "web-target-group"
  }
}

resource "yandex_lb_network_load_balancer" "web" {
  name = "my-network-load-balancer"

  listener {
    name = "web-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.web-group.load_balancer[0].target_group_id
    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/"
      }
    }
  }
}

# диск для gitlab
resource "yandex_compute_disk" "boot-disk" {
  name     = "disk-vm1"
  type     = "network-hdd"
  size     = 15
  image_id = "fd87j6d92jlrbjqbl32q"
  labels = {
    environment = "vm-env-labels"
  }
}

# инстанс для gitlab
resource "yandex_compute_instance" "gitlab" {
  name        = "gitlab"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores         = 2
    memory        = 8
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }
  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat       = true
    #для статического адреса 
    #nat_ip_address = yandex_vpc_address.addr.external_ipv4_address.0.address
  }
  metadata = {
    #ssh-keys = "fill:${file("~/.ssh/id_ed25519.pub")}"
    user-data = "${file("user_data_gitlab.yml")}"
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
  data =  [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]]
}

resource "yandex_dns_recordset" "test" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "test.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]]
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


output "web_loadbalancer_ip" {
  value = [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]][0]
}

output "instance_ip" {
  value = [for instance in yandex_compute_instance_group.web-group.instances : instance.network_interface[0].nat_ip_address]
}

output "instance_gitlab_ip" {
  value = yandex_compute_instance.gitlab.network_interface.0.nat_ip_address
}
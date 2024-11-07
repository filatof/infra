terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      #version = "0.130.0"
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
    key                      = "prod-infra.serv"
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

data "yandex_vpc_network" "EQ-net" {
  name = "EQ-network"  # Имя существующей сети
}

data "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"  # Имя существующей подсети
}

data "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"  # Имя второй подсети
}

data "yandex_vpc_security_group" "EQ-sg" {
  name = "EQ-security-group"  # Имя существующей группы безопасности
}


#-------------определяем группу серверов для prodaction
resource "yandex_compute_instance_group" "web-group" {
  name                = "prod-ig"
  service_account_id  = var.service_account_id
  deletion_protection = false
  instance_template {
    hostname = "prod-{instance.index}"
    platform_id = "standard-v3"
    name         = "prod-{instance.index}" # Присваиваем уникальное имя каждому инстансу в группе
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
      network_id = data.yandex_vpc_network.EQ-net.id
      subnet_ids = ["${data.yandex_vpc_subnet.subnet-a.id}", "${data.yandex_vpc_subnet.subnet-b.id}"]
      nat        = true
    }

    metadata = {
      #файл с ключами для доступа на сервер
      user-data = "${file("user_data_prod.yml")}"
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
    max_expansion   = 0
  }

  load_balancer {
    target_group_name = "web-target-group"
  }
}
# -----------network loadbalancer--------------
resource "yandex_lb_network_load_balancer" "web" {
  name = "load-balancer"

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

data "yandex_dns_zone" "example_zone" {
  name        = "infrastruct"
}

resource "yandex_dns_recordset" "prod" {
  zone_id = data.yandex_dns_zone.example_zone.id
  name    = "prod.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]]
}

output "loadbalancer_ip" {
  value = [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]][0]
}

output "prod_ip" {
  value = [for instance in yandex_compute_instance_group.web-group.instances : instance.network_interface[0].nat_ip_address]
}
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
      network_id = yandex_vpc_network.web-net.id
      subnet_ids = ["${yandex_vpc_subnet.subnet-a.id}", "${yandex_vpc_subnet.subnet-b.id}"]
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

# resource "yandex_dns_zone" "example_zone" {
#   name        = "infrastruct"
#   description = "my zone dns"
#   labels = {
#     label1 = "lable_zone_dns"
#   }
#   zone    = "infrastruct.ru."
#   public  = true
# }

resource "yandex_dns_recordset" "prod" {
  zone_id = yandex_dns_zone.example_zone.id
  name    = "prod.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]]
}


output "loadbalancer_ip" {
  value = [for listener in yandex_lb_network_load_balancer.web.listener : [for addr in listener.external_address_spec : addr.address if listener.name == "web-listener"][0]][0]
}

output "instance_ip" {
  value = [for instance in yandex_compute_instance_group.web-group.instances : instance.network_interface[0].nat_ip_address]
}

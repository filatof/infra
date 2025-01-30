#-------------определяем группу серверов для prodaction
resource "yandex_compute_instance_group" "web-group" {
  count = var.vm_prod
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
      size = count.index
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
# --------------group
resource "yandex_compute_instance_group" "web-group" {
  count = 1
  name                = "prod-ig"
  service_account_id  = var.service_account_id
  deletion_protection = false

  instance_template {
    hostname      = "prod-{instance.index}"
    platform_id   = "standard-v3"
    name          = "prod-{instance.index}"
    resources {
      memory        = 2
      cores         = 2
      core_fraction = 100
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        type     = "network-hdd"
        size     = 10
        image_id = "fd87j6d92jlrbjqbl32q" # ubuntu 22.04
      }
    }

    network_interface {
      network_id = data.yandex_vpc_network.EQ-net.id
      subnet_ids = [data.yandex_vpc_subnet.subnet-a.id, data.yandex_vpc_subnet.subnet-b.id]
      nat        = true
    }

    metadata = {
      user-data = file("user_data.yml")
    }

    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    auto_scale {
      initial_size        = 2  # Начальное количество инстансов
      cpu_utilization_target = 70  # Целевой уровень загрузки ЦП
      measurement_duration = 60  # Время измерения средней загрузки в секундах
      max_size            = 3  # Максимальное количество инстансов
      min_zone_size = 1 # Минимальное количество инстансов
      warmup_duration     = 300  # Время прогрева (секунды)
      stabilization_duration = 600  # Время стабилизации (секунды)
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

# Настройка сетевого балансировщика нагрузки
resource "yandex_lb_network_load_balancer" "web" {
  count = 1
  name  = "load-balancer"

  listener {
    name = "web-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.web-group[0].load_balancer[0].target_group_id
    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/"
      }
    }
  }
}
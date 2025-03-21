data "yandex_compute_image" "my-image" {
  #family    = "my-image"
  image_id = var.image_id
  folder_id = var.folder_id
}

resource "yandex_compute_instance_group" "eq-ig" {
  name               = "prod-ig"
  folder_id          = var.folder_id
  service_account_id = var.service_account_id
  instance_template {
    hostname      = "prod-{instance.index}"
    platform_id   = "standard-v3"
    name          = "prod-{instance.index}"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.my-image.id
        size     = 10
      }
    }
    network_interface {
      network_id = data.yandex_vpc_network.eq-net.id
      subnet_ids = [data.yandex_vpc_subnet.subnet-a.id]
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
      initial_size        = 1  # Начальное количество инстансов
      cpu_utilization_target = 50  # Целевой уровень загрузки ЦП
      measurement_duration = 60  # Время измерения средней загрузки в секундах
      max_size            = 3  # Максимальное количество инстансов
      min_zone_size = 1 # Минимальное количество инстансов
      warmup_duration     = 300  # Время прогрева (секунды)
      stabilization_duration = 600  # Время стабилизации (секунды)
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_creating    = 2
    max_deleting    = 1
    max_unavailable = 1
    max_expansion   = 1

  }

  application_load_balancer {
    target_group_name        = "eq-target-group"
    target_group_description = "Application Load Balancer"
  }

}
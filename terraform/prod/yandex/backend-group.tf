resource "yandex_alb_backend_group" "http-backend-group" {
  name  = "eq-target-group"
  http_backend {
    name   = "http-backend"
    weight = 1
    port   = 8080
    target_group_ids = [
      yandex_compute_instance_group.eq-ig.application_load_balancer[0].target_group_id
    ]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout          = "10s"
      interval         = "10s"
      healthcheck_port = 8080
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "eq-http-router" {
  name          = "eq-http-router"
  labels        = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "virtual-host" {
  name                    = "eq-virtual-host"
  http_router_id          = yandex_alb_http_router.eq-http-router.id
  route {
    name                  = "eq-route"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.http-backend-group.id
        timeout           = "3s"
      }
    }
  }
}

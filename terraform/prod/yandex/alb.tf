resource "yandex_alb_load_balancer" "app-balancer" {
  name        = "app-loadbalancer"
  network_id  = data.yandex_vpc_network.eq-net.id
  security_group_ids = [data.yandex_vpc_security_group.EQ-sg.id]

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = data.yandex_vpc_subnet.subnet-a.id
    }
  }

  listener {
    name = "eq-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 8080 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.eq-http-router.id
      }
    }
  }
}
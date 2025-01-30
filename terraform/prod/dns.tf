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
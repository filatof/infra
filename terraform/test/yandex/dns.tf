#--------ADD zone infrastruct.ru
resource "yandex_dns_zone" "zone_ru" {
  name        = "infrastruct-ru"
  description = "my dns"
  labels = {
    label1 = "lable_zone_dns_ru"
  }
  zone    = "infrastruct.ru."
  public  = true
}

#-----------Consul cluster
resource "yandex_dns_recordset" "record" {
  count = var.consul
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "consul${count.index + 1}.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.consul[count.index].network_interface[0].nat_ip_address]
}

#----------Gitlab-----registry
resource "yandex_dns_recordset" "gitlab" {
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "gitlab.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.gitlab.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "registry" {
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "registry.gitlab.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.gitlab.network_interface.0.nat_ip_address]
}

#-----------Prometheus --- Grafana
resource "yandex_dns_recordset" "prometheus" {
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "prometheus.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.prometheus.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "grafana" {
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "grafana.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data =  [yandex_compute_instance.prometheus.network_interface.0.nat_ip_address]
}

#-----------test instances
resource "yandex_dns_recordset" "test" {
  count = var.vm_test
  zone_id = yandex_dns_zone.zone_ru.id
  name    = "test-${count.index + 1}.infrastruct.ru."
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.test[count.index].network_interface[0].nat_ip_address]
}



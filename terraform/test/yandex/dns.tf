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

#----------Gitlab
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



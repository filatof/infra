#-------------определяем  сеть
resource "yandex_vpc_network" "EQ-net" {
  name = "EQ-network"
}

#-----------оперделяем подсети в разных зонах
resource "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.EQ-net.id
}

resource "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.EQ-net.id
}

#----------security group
resource "yandex_vpc_security_group" "EQ-sg" {
  name        = "EQ-security-group"
  description = "description for my security group"
  network_id  = yandex_vpc_network.EQ-net.id

  labels = {
    my-label = "sg-label"
  }

  dynamic "ingress" {
    for_each = ["80", "443","22", "2222", "3000", "3100", "8080", "9090", "9080", "9093", "9095", "9100", "9113", "9104" ]
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

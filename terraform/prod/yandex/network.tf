data "yandex_vpc_network" "EQ-net" {
  name = "EQ-network"
}

data "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"
}

data "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"
}

data "yandex_vpc_security_group" "EQ-sg" {
  name = "EQ-security-group"
}
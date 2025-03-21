data "yandex_vpc_network" "eq-net" {
  name = "eq-network"
}

data "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"
}

# data "yandex_vpc_subnet" "subnet-b" {
#   name = "subnet-b"
# }

data "yandex_vpc_security_group" "EQ-sg" {
  name = "eq-security-group"
}
data "yandex_vpc_network" "EQ-net" {
  name = "EQ-network"  # Имя существующей сети
}

data "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"  # Имя существующей подсети
}

data "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"  # Имя второй подсети
}

data "yandex_vpc_security_group" "EQ-sg" {
  name = "EQ-security-group"  # Имя существующей группы безопасности
}


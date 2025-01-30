terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.133.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "terraform-state-standart"
    region = "ru-central1"
    key    = "consul-cluster.tfstate"
    shared_credentials_files = [ "storage.key" ]
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}

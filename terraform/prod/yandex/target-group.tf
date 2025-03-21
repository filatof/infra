# resource "yandex_alb_target_group" "eq-target-group" {
#   name           = "eq-target-group"
#   dynamic "target" {
#     for_each = yandex_compute_instance_group.eq-ig.instances
#     content {
#       subnet_id  = data.yandex_vpc_subnet.subnet-a.id
#       ip_address = target.value.network_interface[0].ip_address
#     }
#   }
# }
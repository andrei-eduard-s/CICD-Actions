output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "bastion_public_dns" {
  value = module.bastion.public_dns
}

output "app_foo_tg_arn" {
  value = module.app_foo.target_group_arn
}

output "app_bar_tg_arn" {
  value = module.app_bar.target_group_arn
}

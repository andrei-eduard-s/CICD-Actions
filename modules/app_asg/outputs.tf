output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "app_sg_id" {
  value = aws_security_group.app_sg.id
}

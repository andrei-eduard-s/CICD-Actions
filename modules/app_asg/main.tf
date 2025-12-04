# AMI lookup (Ubuntu 22.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for app (traffic only from ALB SG - rule added at root)
resource "aws_security_group" "app_sg" {
  name   = "app-sg-${var.page_text}"
  vpc_id = var.vpc_id

  # no direct ingress cidr here; ALB -> app SG rule is added at root
  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "app-sg-${var.page_text}" })
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>${var.page_text}</h1>" > /var/www/html/index.nginx-debian.html
  EOF
}

resource "aws_launch_template" "lt" {
  name_prefix   = "app-lt-${var.page_text}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(local.user_data)

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Role = "app", App = var.page_text })
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "asg-${var.page_text}"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = var.private_subnets

  health_check_type         = "ELB"
  health_check_grace_period = 30

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "app-${var.page_text}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-${var.page_text}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type  = "instance"

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 15
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 5
  }

  tags = merge(var.tags, { Name = "tg-${var.page_text}" })
}

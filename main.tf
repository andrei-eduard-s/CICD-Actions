# Temporary change to test GitHub Actions #3

terraform {
  required_version = ">= 1.4.0"

  backend "s3" {
    bucket         = "andreis-tf-state-cicd-actions"
    key            = "envs/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- VPC official module: 10.0.0.0/16, 2x public, 2x private, single NAT (no HA)
module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "andreis-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Project = "tf-minimal-AndreiS" }
}

# --- Application Load Balancer (public)
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = module.network.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "tf-minimal-AndreiS" }
}

resource "aws_lb" "app_alb" {
  name               = "andreis-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.network.public_subnets

  tags = { Project = "tf-minimal-AndreiS" }
}

# --- App ASG #1 (Foo) in private subnets
module "app_foo" {
  source          = "./modules/app_asg"
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  key_name        = var.key_name
  instance_type   = var.instance_type
  page_text       = "Foo"
  tags            = { Project = "tf-minimal-AndreiS" }
}

# --- App ASG #2 (Bar) in private subnets
module "app_bar" {
  source          = "./modules/app_asg"
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  key_name        = var.key_name
  instance_type   = var.instance_type
  page_text       = "Bar"
  tags            = { Project = "tf-minimal-AndreiS" }
}

# --- Allow ALB SG -> App SGs on port 80
resource "aws_security_group_rule" "alb_to_app_foo" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = module.app_foo.app_sg_id
}

resource "aws_security_group_rule" "alb_to_app_bar" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = module.app_bar.app_sg_id
}

# --- ALB Listener 80: forward catre ambele target groups (1:1)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      # aceste variabile pastreaza host/port/protocol din request
      host     = "#{host}"
      protocol = "#{protocol}"
      port     = "#{port}"
      query    = "#{query}"
      path     = "/foo"
    }
  }
}

resource "aws_lb_listener_rule" "foo" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = module.app_foo.target_group_arn
  }
  condition {
    path_pattern {
      values = ["/foo*"]
    }
  }
}

resource "aws_lb_listener_rule" "bar" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = module.app_bar.target_group_arn
  }
  condition {
    path_pattern {
      values = ["/bar*"]
    }
  }
}

# --- Bastion host (public subnet) - SSH only from my_ip_cidr
module "bastion" {
  source    = "./modules/bastion"
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnets[0]

  my_ip_cidr    = var.my_ip_cidr
  key_name      = var.key_name
  instance_type = var.instance_type

  tags = { Project = "tf-minimal-AndreiS" }
}

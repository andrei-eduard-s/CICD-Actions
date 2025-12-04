variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name in the selected region"
  type        = string
}

variable "my_ip_cidr" {
  description = "Public IP in CIDR (x.x.x.x/32) for SSH to bastion"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type for app and bastion"
  type        = string
  default     = "t3.micro"
}

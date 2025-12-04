variable "vpc_id" {
  type        = string
  description = "VPC ID for SG"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID for bastion"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your IP in CIDR (x.x.x.x/32) for SSH"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "instance_type" {
  type        = string
  description = "Bastion instance type"
  default     = "t3.micro"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

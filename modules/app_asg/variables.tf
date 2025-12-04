variable "private_subnets" {
  type        = list(string)
  description = "Private subnets for the ASG"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "page_text" {
  type        = string
  description = "Text to render in NGINX index (Foo/Bar)"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

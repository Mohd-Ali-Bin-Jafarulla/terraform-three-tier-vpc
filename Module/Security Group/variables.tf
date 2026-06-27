#-------------VPC ID association with Security Group----------------

variable "vpc_id" {
  description = "The VPC ID to associate with the security group"
  type        = string
}

variable"environment" {
  description = "The environment for the security group (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "The project name for the security group"
  type        = string
}
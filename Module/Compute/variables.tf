variable "environment" {type = string}
variable "project_name" {type = string}
variable "vpc_id" {type = string}
variable "public_subnet_id" {type = list(string) }
variable "app_subnet_id" {type = list(string)}
variable "alb_sg_id" {type = string}
variable "app_sg_id" {type = string}

variable "instance_type" {
  type = string
  default = "t2.micro"
}
variable "environment" {}
variable "project_name" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {type = list(string)}
variable "app_subnet_cidrs" {type = list(string)}
variable "db_subnet_cidrs" {type = list(string)}
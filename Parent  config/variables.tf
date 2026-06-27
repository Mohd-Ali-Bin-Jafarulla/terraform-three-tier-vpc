#--------------Region----------------
variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string
    }

#----------environment----------------
variable "environment" {
    description = "Environment name (e.g., dev, staging, prod)"
    type        = string
    }

#-----------Project Name----------------
variable "project_name" {
    description = "Project name for resource naming"
    type        = string
    }

#-----------VPC CIDR Block----------------
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    }

#-----------Public Subnet CIDR Blocks----------------
variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for public subnets"
    type        = list(string)
    }

#-----------Private Subnet CIDR Blocks----------------
variable "private_subnet_cidrs" {
    description = "List of CIDR blocks for private subnets"
    type        = list(string)
    }

#----------App subnet CIDR Blocks----------------
variable "app_subnet_cidrs" {
    description = "List of CIDR blocks for application subnets"
    type        = list(string)
    }

#----------Database subnet CIDR Blocks----------------
variable "db_subnet_cidrs" {
    description = "List of CIDR blocks for database subnets"
    type        = list(string)
    }
#---------------Instance type-----------------
    variable "instance_type" {
  description = "The EC2 instance type for the application tier"
  type        = string
  default     = "t2.micro" 
}
#-------------environment variable for the DB----------------

variable "environment" {
  description = "The environment for the database (e.g., dev, staging, prod)"
  type        = string

}

#-------------project_name variable for the DB----------------

variable "project_name" {
  description = "The project name for the database"
  type        = string
}

#-------------Subnet IDs for the DB----------------

variable "db_subnet_ids" {
  description = "subnet IDs for the Database"
  type = list(string)
}

#-------------Security group variable for the DB----------------

variable "db_sg_id" {
  description = "The security group ID for the database"
  type        = string
}

#-------------Database name-------------------

variable "db_name" {
  description = "the name of the database to create"
  type = string
}

#------------Databse Username-----------------

variable "db_username" {
  description = "Username for the DB user"
  type = string
}

#-------------Database username password----------

variable "db_password" {
  description = "Password for the master DB user"
  type = string
  sensitive = true
}

#---------------VPC ID---------------------------

variable "vpc_id" {
  description = "The ID of the VPC where the database subnet group will be created"
  type        = string
}
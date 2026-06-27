#-----------VPC Module----------------

module "vpc" {
 source = "./modules/vpc"
 project_name = var.project_name
 environment = var.environment
 vpc_cidr = var.vpc_cidr
 public_subnet_cidrs = var.public_subnet_cidrs
 app_subnet_cidrs = var.app_subnet_cidrs
 db_subnet_cidrs = var.db_subnet_cidrs
}

#-----------Security Group Module----------------

module "security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

#-------------Database Module--------------

variable "db_name" {
  type = string
  default = "myappdb"
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

module "database" {
  source          = "./modules/database" 
  project_name    = var.project_name
  environment     = var.environment
  db_subnet_ids   = module.vpc.db_subnet_ids
  vpc_id = module.vpc.vpc_id
  db_sg_id        = module.security_group.db_sg_id 
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
}
#--------------compute module--------------

module "compute" {
  source = "./modules/compute"
  project_name = var.project_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids
  app_subnet_id = module.vpc.public_subnet_ids
  alb_sg_id = module.security_group.alb_sg_id
  app_sg_id = module.security_group.app_sg_id
  instance_type = var.instance_type
}
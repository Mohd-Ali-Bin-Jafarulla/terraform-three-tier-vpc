#----------DB Subnet Group (Tells RDS which subnets/AZs it can live in)

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  description = "subnet group for 3-tier DB layer"
}

#--------------RDS Instance

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"
  allocated_storage = 20                                # Free tier allows up to 20 GB
  max_allocated_storage = 100                           # Auto-scaling storage limit
  engine = "postgres"
  engine_version = "15.18"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class = "db.t3.micro"
  multi_az             = true
  db_name = var.db_name
  username = var.db_username
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  skip_final_snapshot = true                       # Prevents errors/costs when running 'terraform destroy'                 

tags = {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
  }
}

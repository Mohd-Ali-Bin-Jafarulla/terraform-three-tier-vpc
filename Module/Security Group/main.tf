#------------1.ALB Security Group (Public)----------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id

    #Allow inbound HTTP traffic from anywhere

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    #Allow inbound HTTPS traffic from anywhere

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }  

    #Allow outbound traffic to anywhere

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-alb-sg"
        Environment = var.environment
    }
}

#------------2.App Security Group (Private)----------------

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for the App"
  vpc_id      = var.vpc_id

  #Allow inbound traffic from ALB security group on port 80

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  #Outbound: Allow all (for updates, patches, etc.)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-app-sg"
        Environment = var.environment
    }
}

#------------3.DB Security Group (Private)----------------

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for the DB"
  vpc_id      = var.vpc_id

  #Only allow PostgreSQL/MySQL port (e.g., 5432) from the App Security Group

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  #Outbound: Allow all (for updates, patches, etc.)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-db-sg"
        Environment = var.environment
    }
}


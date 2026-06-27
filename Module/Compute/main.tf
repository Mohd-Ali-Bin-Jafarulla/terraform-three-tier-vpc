#---------------1.Fetch latest Amazon linux 2 AMI dynamically

data "aws_ami" "amzon_linux_2" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }
}

#------------------2.Applicaion Load Balancer (Public Tier)

resource "aws_lb" "external" {
  name = "${var.project_name}-${var.environment}-alb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [var.alb_sg_id]
  subnets = var.public_subnet_id

tags = {
  name  = "${var.project_name}-${var.environment}-alb"
  environment = var.environment
 }
}

#-----------------3.ALB Target Group (Points to our App Tier)

resource "aws_alb_target_group" "app" {
  name = "${var.project_name}-${var.environment}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "instance"

  health_check {
    path = "/"
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    matcher = "200"
  }
}


#-----------------------4.ALP HTTP Listener

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
}

#-----------------------5.Launch Template for ASG

resource "aws_launch_template" "app" {
  name_prefix = "${var.project_name}-${var.environment}-template-"
  image_id = data.aws_ami.amzon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true  
    security_groups = [var.app_sg_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Forces IMDSv2
    http_put_response_hop_limit = 2          # Allows tokens to hop down to applications/scripts cleanly
  }
  # Simple User Data script to start a mock webserver showing high availability
 user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              
              LOCAL_IP=$(hostname -I | awk '{print $1}')
              echo "<h1>Hello World from IP: $LOCAL_IP inside our Secure 3-Tier VPC!</h1>" > /var/www/html/index.html
              EOF
  )
tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-server"
      Environment = var.environment
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


#-----------------------6. Auto Scaling Group spanning across Private App Subnets

resource "aws_autoscaling_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-asg-"
  vpc_zone_identifier = var.app_subnet_id
  target_group_arns = [aws_alb_target_group.app.arn]

  min_size = 1
  max_size = 2
  desired_capacity = 2 # Forces deployment to both Availability Zones for HA

  launch_template {
    id  = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  
  }

  tag {
    key = "Name"
    value = "${var.project_name}-${var.environment}-app-server"
    propagate_at_launch = true
  }
}
#------------application load balancer security group output----------------
output "alb_sg_id" {
  value = aws_security_group.alb.id
}

#------------Application Security Group output----------------
output "app_sg_id" {
  value = aws_security_group.app.id
}

#------------Database Security Group output----------------
output "db_sg_id" {
  value = aws_security_group.db.id
}

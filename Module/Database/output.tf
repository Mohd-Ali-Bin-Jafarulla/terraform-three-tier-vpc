output "db_endpoint" {
  value = aws_db_instance.main.endpoint
  description = "the connection endpoint for the RDS instance"
}

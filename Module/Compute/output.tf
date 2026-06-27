output "alb_dns_name" {
  value       = aws_lb.external.dns_name
  description = "The public DNS name of the application load balancer"
}
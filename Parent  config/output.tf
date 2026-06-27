output "application_url" {
  value       = "http://${module.compute.alb_dns_name}"
  description = "Access your application using this URL"
}
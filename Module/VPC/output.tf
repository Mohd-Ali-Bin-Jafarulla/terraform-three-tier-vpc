#-----------VPC IDs output-----------

output "vpc_id" {
    value       = aws_vpc.main.id
    description = "The ID of the VPC"
}

#----------Public Subnet IDs-----------

output "public_subnet_ids" {
  value       = aws_subnet.public.*.id
  description = "The IDs of the public subnets"
}

#----------App Subnet IDs-----------

output "app_subnet_ids" {
  value       = aws_subnet.app.*.id
  description = "The IDs of the app subnets"
}

#----------DB Subnet IDs-----------

output "db_subnet_ids" {
  value       = aws_subnet.db.*.id
  description = "The IDs of the db subnets"
}

# =============================================================================
# Outputs
# =============================================================================
# Exposes key resource identifiers and endpoints for use by other Terraform
# configurations, CI/CD pipelines, or application deployment scripts.
# =============================================================================

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id,
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id,
  ]
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------

output "rds_primary_endpoint" {
  description = "Connection endpoint for the primary RDS PostgreSQL instance."
  value       = aws_db_instance.primary.endpoint
}

output "rds_primary_identifier" {
  description = "Identifier of the primary RDS PostgreSQL instance."
  value       = aws_db_instance.primary.identifier
}

output "rds_replica_endpoint" {
  description = "Connection endpoint for the RDS read replica."
  value       = aws_db_instance.replica.endpoint
}

output "rds_replica_identifier" {
  description = "Identifier of the RDS read replica."
  value       = aws_db_instance.replica.identifier
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

output "app_security_group_id" {
  description = "ID of the application-tier security group."
  value       = aws_security_group.app_sg.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds_sg.id
}

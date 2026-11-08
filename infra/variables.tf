# =============================================================================
# Input Variables
# =============================================================================
# Defines all configurable parameters for the e-commerce infrastructure.
# Sensitive variables (db_username, db_password) have no defaults and must
# be supplied at plan/apply time via .tfvars or environment variables.
# =============================================================================

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where all resources will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging, development)."
  type        = string
  default     = "production"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_port" {
  description = "Port on which the application listens."
  type        = number
  default     = 8080
}

# -----------------------------------------------------------------------------
# Database (RDS)
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class for the PostgreSQL database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB for the primary RDS instance."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for the RDS instances."
  type        = string
  default     = "14.13"
}

variable "db_name" {
  description = "Name of the default database created on the primary RDS instance."
  type        = string
  default     = "ecommerce_db"
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance. Treated as sensitive."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance. Treated as sensitive."
  type        = string
  sensitive   = true
}

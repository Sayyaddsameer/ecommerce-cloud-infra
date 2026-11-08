# =============================================================================
# RDS PostgreSQL – Primary + Read Replica
# =============================================================================
# Provisions a PostgreSQL primary instance in private subnets with a same-
# region read replica. Both instances are encrypted at rest, not publicly
# accessible, and secured by the rds_sg security group.
# =============================================================================

# -----------------------------------------------------------------------------
# DB Subnet Group (private subnets only)
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for ${var.project_name} RDS instances"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id,
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# DB Parameter Group
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "postgres14" {
  name        = "${var.project_name}-${var.environment}-pg14-params"
  family      = "postgres14"
  description = "Custom parameter group for ${var.project_name} PostgreSQL 14"

  # Enable slow-query logging (>= 1 second)
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  # Log all DDL statements
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-pg14-params"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Primary RDS Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-db-primary"

  # Engine
  engine         = "postgres"
  engine_version = var.db_engine_version

  # Sizing
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = false
  publicly_accessible    = false

  # Parameter group
  parameter_group_name = aws_db_parameter_group.postgres14.name

  # Backup & snapshots
  backup_retention_period = 1 # Minimum required for read replica support
  skip_final_snapshot     = true

  # Encryption
  storage_encrypted = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-primary"
    Project     = var.project_name
    Environment = var.environment
    Role        = "primary"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Read Replica
# -----------------------------------------------------------------------------
# The replica inherits engine, storage, subnet group, and parameter group
# from the source (primary) instance.

resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-db-replica"

  # Link to the primary instance
  replicate_source_db = aws_db_instance.primary.identifier

  # Sizing (can differ from primary for cost optimisation)
  instance_class = var.db_instance_class

  # Networking
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  # Snapshots
  skip_final_snapshot = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-replica"
    Project     = var.project_name
    Environment = var.environment
    Role        = "replica"
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [aws_db_instance.primary]
}

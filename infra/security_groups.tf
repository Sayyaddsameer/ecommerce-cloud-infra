# =============================================================================
# Security Groups
# =============================================================================
# Defines two security groups:
#   1. app_sg  – allows inbound traffic on the application port (for testing)
#   2. rds_sg  – allows inbound PostgreSQL traffic only from the app_sg
# =============================================================================

# -----------------------------------------------------------------------------
# Application Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow inbound traffic on the application port"
  vpc_id      = aws_vpc.main.id

  # Inbound: application port from anywhere (for testing purposes)
  ingress {
    description = "Application port access"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL access only from the application security group"
  vpc_id      = aws_vpc.main.id

  # Inbound: PostgreSQL port from the application security group only
  ingress {
    description     = "PostgreSQL access from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  # Outbound: allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

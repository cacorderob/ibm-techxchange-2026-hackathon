# =============================================================================
# Módulo: rds-sqlserver
# Descripción: Aprovisiona una instancia RDS SQL Server Express en AWS
# Recursos: aws_db_instance, aws_db_subnet_group, aws_security_group
# =============================================================================

# -----------------------------------------------------------------------------
# Security Group: base — sin reglas inline para compatibilidad con checkov
# Las reglas se definen en recursos separados aws_vpc_security_group_*_rule
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.environment}-sg-rds"
  description = "Security group para RDS SQL Server - acceso restringido al SG de EC2"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-rds"
  })
}

# Regla de ingreso: SQL Server (1433) solo desde el Security Group de la EC2
# La RDS no es accesible desde internet — principio de mínimo privilegio
resource "aws_vpc_security_group_ingress_rule" "sqlserver_from_ec2" {
  security_group_id            = aws_security_group.rds_sg.id
  description                  = "SQL Server desde Security Group de EC2"
  from_port                    = 1433
  to_port                      = 1433
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ec2_security_group_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-rds-sqlserver-ingress"
  })
}

# Regla de egreso: todo el tráfico saliente permitido
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  description       = "Todo el trafico saliente permitido"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-rds-all-egress"
  })
}

# -----------------------------------------------------------------------------
# DB Subnet Group: agrupa las subnets disponibles para la instancia RDS
# RDS requiere un subnet group aunque sea de zona única
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.project_name}-${var.environment}-dbsubnetgroup"
  description = "Subnet group para RDS SQL Server del proyecto ${var.project_name}"
  subnet_ids  = var.db_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dbsubnetgroup"
  })
}

# -----------------------------------------------------------------------------
# Instancia RDS: SQL Server Express Edition
# - Motor: sqlserver-ex (Express, incluye licencia, sin costo adicional)
# - Multi-AZ deshabilitado (entorno de prueba/hackathon)
# - skip_final_snapshot = true (no productivo)
# - Credenciales NUNCA en código, solo desde variables sensibles
# -----------------------------------------------------------------------------
resource "aws_db_instance" "sqlserver" {
  identifier     = "${var.project_name}-${var.environment}-rds-sqlserver"
  engine         = "sqlserver-ex"
  engine_version = var.engine_version
  instance_class = var.db_instance_class
  license_model  = "license-included"

  # Credenciales del administrador — provienen de variables sensibles
  # Nunca hardcodear estos valores
  username = var.db_username
  password = var.db_password

  # Almacenamiento
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Red
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  # Alta disponibilidad — deshabilitada para entorno de prueba
  multi_az = false

  # Mantenimiento y backups
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  # Zona horaria compatible con SQL Server en Windows
  timezone = "Eastern Standard Time"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sqlserver"
  })
}

# -----------------------------------------------------------------------------
# Locals: tags comunes aplicados a todos los recursos del módulo
# -----------------------------------------------------------------------------
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

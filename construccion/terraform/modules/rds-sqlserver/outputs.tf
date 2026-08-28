# =============================================================================
# Outputs — Módulo rds-sqlserver
# =============================================================================

output "db_instance_id" {
  description = "Identificador de la instancia RDS creada."
  value       = aws_db_instance.sqlserver.id
}

output "db_endpoint" {
  description = "Endpoint de conexión a la instancia RDS SQL Server (host:puerto)."
  value       = aws_db_instance.sqlserver.endpoint
  sensitive   = true
}

output "db_address" {
  description = "Dirección (hostname) de la instancia RDS SQL Server."
  value       = aws_db_instance.sqlserver.address
  sensitive   = true
}

output "db_port" {
  description = "Puerto de conexión a la instancia RDS SQL Server (1433)."
  value       = aws_db_instance.sqlserver.port
}

output "db_security_group_id" {
  description = "ID del Security Group asociado a la instancia RDS."
  value       = aws_security_group.rds_sg.id
}

output "db_subnet_group_name" {
  description = "Nombre del DB Subnet Group utilizado por la instancia RDS."
  value       = aws_db_subnet_group.rds_subnet_group.name
}

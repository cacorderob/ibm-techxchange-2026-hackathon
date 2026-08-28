# =============================================================================
# outputs.tf — Outputs del root module
# Expone los valores útiles tras el aprovisionamiento
# Los outputs sensibles están marcados con sensitive = true
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs de EC2
# -----------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "ID de la instancia EC2 Windows Server creada."
  value       = module.ec2_windows.instance_id
}

output "ec2_public_ip" {
  description = "IP pública de la instancia EC2 Windows Server, asignada dinámicamente por AWS."
  value       = module.ec2_windows.instance_public_ip
}

output "ec2_private_ip" {
  description = "IP privada de la instancia EC2 dentro de la VPC."
  value       = module.ec2_windows.instance_private_ip
}

output "ec2_security_group_name" {
  description = "Nombre del Security Group asociado a la instancia EC2."
  value       = module.ec2_windows.security_group_name
}

output "ec2_key_pair_name" {
  description = "Nombre del Key Pair creado en AWS para la instancia EC2."
  value       = module.ec2_windows.key_pair_name
}

output "ec2_ami_id" {
  description = "ID de la AMI de Windows Server 2022 utilizada para la instancia."
  value       = module.ec2_windows.ami_id
}

# -----------------------------------------------------------------------------
# Outputs de RDS
# -----------------------------------------------------------------------------

output "rds_instance_id" {
  description = "Identificador de la instancia RDS SQL Server creada."
  value       = module.rds_sqlserver.db_instance_id
}

output "rds_endpoint" {
  description = "Endpoint de conexión a la instancia RDS SQL Server (host:puerto). Valor sensible."
  value       = module.rds_sqlserver.db_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "Dirección (hostname) de la instancia RDS SQL Server. Valor sensible."
  value       = module.rds_sqlserver.db_address
  sensitive   = true
}

output "rds_port" {
  description = "Puerto de conexión a la instancia RDS SQL Server (1433)."
  value       = module.rds_sqlserver.db_port
}

output "rds_security_group_id" {
  description = "ID del Security Group asociado a la instancia RDS."
  value       = module.rds_sqlserver.db_security_group_id
}

# =============================================================================
# Variables — Módulo rds-sqlserver
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto. Se usa para construir los nombres de los recursos."
  type        = string
}

variable "environment" {
  description = "Nombre del ambiente (ej: dev, staging, prod). Se usa en tags y nombres de recursos."
  type        = string
}

variable "owner" {
  description = "Responsable o propietario del recurso. Se usa en el tag Owner."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se creará el Security Group de la RDS."
  type        = string
}

variable "db_subnet_ids" {
  description = "Lista de IDs de subnets para el DB Subnet Group. RDS requiere al menos dos subnets en distintas zonas."
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "ID del Security Group de la instancia EC2. Se usa para restringir el acceso al puerto 1433."
  type        = string
}

variable "db_instance_class" {
  description = "Tipo de instancia para la base de datos RDS (ej: db.t3.micro)."
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "Versión del motor SQL Server Express para RDS (ej: 15.00.4153.1.v1)."
  type        = string
  default     = "15.00.4153.1.v1"
}

variable "db_username" {
  description = "Nombre de usuario administrador de la base de datos SQL Server. Debe configurarse como variable sensible en Terraform Cloud."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña del administrador de la base de datos SQL Server. Debe configurarse como variable sensible en Terraform Cloud. Mínimo 8 caracteres."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "La contraseña de la base de datos debe tener al menos 8 caracteres."
  }
}

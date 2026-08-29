# =============================================================================
# variables.tf — Variables del root module
# IMPORTANTE: Los valores sensibles NO se definen aquí.
# Se configuran como variables en el workspace 'hackaton' de Terraform Cloud.
# =============================================================================

# -----------------------------------------------------------------------------
# Variables generales del proyecto
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Región de AWS donde se aprovisionarán todos los recursos."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto. Se usa para construir los nombres de los recursos y tags."
  type        = string
  default     = "ibm-techxchange-2026"
}

variable "environment" {
  description = "Nombre del ambiente del deployment (ej: dev, staging, prod, hackaton)."
  type        = string
  default     = "hackaton"
}

variable "owner" {
  description = "Responsable o propietario de los recursos. Se usa en el tag Owner."
  type        = string
}

# -----------------------------------------------------------------------------
# Variables de red
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID de la VPC donde se crearán los recursos. Dejar vacío para usar la VPC por defecto de us-east-1."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID de la subnet pública donde se desplegará la instancia EC2."
  type        = string
  default     = ""
}

variable "db_subnet_ids" {
  description = "Lista de IDs de subnets para el DB Subnet Group de RDS. Se requieren al menos dos subnets en distintas zonas de disponibilidad."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Variables de EC2
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "Tipo de instancia EC2 para la máquina virtual Windows Server."
  type        = string
  default     = "t2.micro"
}

variable "allowed_rdp_cidr" {
  description = "CIDR desde el cual se permite el acceso RDP (puerto 3389) a la instancia EC2. No usar 0.0.0.0/0."
  type        = string
}

# -----------------------------------------------------------------------------
# Variables de RDS
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "Tipo de instancia para la base de datos RDS SQL Server."
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "Versión del motor SQL Server Express para RDS."
  type        = string
  default     = "15.00.4153.1.v1"
}

variable "db_username" {
  description = "Nombre de usuario administrador de la base de datos SQL Server. Configurar como variable sensible en Terraform Cloud."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña del administrador de la base de datos SQL Server. Configurar como variable sensible en Terraform Cloud. Mínimo 8 caracteres."
  type        = string
  sensitive   = true
}

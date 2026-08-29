# =============================================================================
# Variables — Módulo ec2-windows
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

variable "instance_type" {
  description = "Tipo de instancia EC2 (ej: t3.micro, t3.small)."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "ID de la VPC donde se creará el Security Group de la EC2."
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se desplegará la instancia EC2."
  type        = string
}

variable "allowed_rdp_cidr" {
  description = "CIDR desde el cual se permite el acceso RDP (puerto 3389). No usar 0.0.0.0/0."
  type        = string

  validation {
    condition     = var.allowed_rdp_cidr != "0.0.0.0/0"
    error_message = "El CIDR para RDP no puede ser 0.0.0.0/0. Especifica un rango de IP restringido."
  }
}


# =============================================================================
# versions.tf — Versiones y backend de Terraform
# Organización Terraform Cloud: GBM-HA-TEST
# Proyecto: Carlos pruebas
# Workspace: hackaton
# =============================================================================

terraform {
  # Versión mínima de Terraform requerida
  required_version = ">= 1.5"

  # Backend remoto en Terraform Cloud
  # Las credenciales AWS y variables sensibles se configuran en el workspace
  # de Terraform Cloud, NO en este archivo
  cloud {
    organization = "GBM-HA-TEST"

    workspaces {
      name = "hackaton"
    }
  }

  # Proveedores requeridos con versiones fijadas
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Configuración del proveedor AWS
# Las credenciales se inyectan desde variables de entorno de Terraform Cloud:
#   AWS_ACCESS_KEY_ID     → Variable de entorno en workspace hackaton
#   AWS_SECRET_ACCESS_KEY → Variable de entorno en workspace hackaton
# NUNCA se hardcodean las credenciales aquí
# =============================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_name
    }
  }
}

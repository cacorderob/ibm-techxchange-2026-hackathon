# =============================================================================
# main.tf — Root module
# Instancia los módulos ec2-windows y rds-sqlserver
# Obtiene información de la VPC por defecto si no se especifica vpc_id
# =============================================================================

# -----------------------------------------------------------------------------
# Data sources: VPC y subnets por defecto de AWS en us-east-1
# Se usan cuando no se especifican vpc_id y subnet_id como variables
# -----------------------------------------------------------------------------

# Obtiene la VPC por defecto de la región si no se especifica una VPC
data "aws_vpc" "default" {
  default = true
}

# Obtiene todas las subnets de la VPC por defecto
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Obtiene la primera subnet disponible para la EC2
data "aws_subnet" "first" {
  id = tolist(data.aws_subnets.default.ids)[0]
}

# -----------------------------------------------------------------------------
# Locals: valores derivados para simplificar la configuración
# Usa la VPC y subnets por defecto si no se especifican variables
# -----------------------------------------------------------------------------
locals {
  # Usa la VPC provista como variable, o la VPC por defecto de AWS
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  # Usa la subnet provista como variable, o la primera subnet por defecto
  subnet_id = var.subnet_id != "" ? var.subnet_id : data.aws_subnet.first.id

  # Usa las subnets provistas como variable, o todas las subnets por defecto
  db_subnet_ids = length(var.db_subnet_ids) > 0 ? var.db_subnet_ids : tolist(data.aws_subnets.default.ids)
}

# -----------------------------------------------------------------------------
# Módulo EC2 Windows Server 2022
# -----------------------------------------------------------------------------
module "ec2_windows" {
  source = "./modules/ec2-windows"

  # Variables generales
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  # Variables de instancia
  instance_type = var.instance_type

  # Variables de red
  vpc_id    = local.vpc_id
  subnet_id = local.subnet_id

  # Variables de seguridad
  allowed_rdp_cidr = var.allowed_rdp_cidr
}

# -----------------------------------------------------------------------------
# Módulo RDS SQL Server Express
# -----------------------------------------------------------------------------
module "rds_sqlserver" {
  source = "./modules/rds-sqlserver"

  # Variables generales
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  # Variables de instancia
  db_instance_class = var.db_instance_class
  engine_version    = var.engine_version

  # Variables de red
  vpc_id                = local.vpc_id
  db_subnet_ids         = local.db_subnet_ids
  ec2_security_group_id = module.ec2_windows.security_group_id

  # Credenciales de administrador (sensibles — provienen de Terraform Cloud)
  db_username = var.db_username
  db_password = var.db_password
}

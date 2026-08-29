# =============================================================================
# Módulo: ec2-windows
# Descripción: Aprovisiona una instancia EC2 con Windows Server 2022 en AWS
# Recursos: aws_instance, aws_security_group, data aws_ami
# Acceso: RDP con usuario/contraseña de administrador de Windows (no SSH)
# =============================================================================

# -----------------------------------------------------------------------------
# Data source: AMI más reciente de Windows Server 2022 (owner: amazon)
# Se busca dinámicamente para siempre usar la versión más reciente disponible
# -----------------------------------------------------------------------------
data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# Security Group: base — sin reglas inline para compatibilidad con checkov
# Las reglas se definen en recursos separados aws_vpc_security_group_*_rule
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${var.environment}-sg-ec2"
  description = "Security group para EC2 Windows - permite RDP restringido"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-ec2"
  })
}

# Regla de ingreso: RDP (3389) restringido al CIDR configurado por variable
# No se permite 0.0.0.0/0 — la variable tiene validación en variables.tf
resource "aws_vpc_security_group_ingress_rule" "rdp" {
  security_group_id = aws_security_group.ec2_sg.id
  description       = "RDP desde CIDR permitido"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_rdp_cidr

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-ec2-rdp-ingress"
  })
}

# Regla de egreso: salida a internet requerida para actualizaciones de Windows
# checkov:skip=CKV_AWS_382: Egreso abierto necesario para actualizaciones del SO y conectividad saliente en entorno de hackathon
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Todo el trafico saliente permitido — requerido para actualizaciones de Windows"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-ec2-all-egress"
  })
}

# -----------------------------------------------------------------------------
# Instancia EC2: Windows Server 2022, t2.micro, con IP pública dinámica
# La IP pública es asignada por AWS al momento del aprovisionamiento
# -----------------------------------------------------------------------------
resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows_server_2022.id
  instance_type = var.instance_type

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true # checkov:skip=CKV_AWS_88: IP publica requerida para acceso RDP directo en entorno de hackathon

  # IMDSv2 obligatorio — previene ataques SSRF contra el metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Monitoreo detallado habilitado para visibilidad de métricas
  monitoring = true

  # Disco raíz: gp3 para mejor rendimiento y costo
  # checkov:skip=CKV_AWS_135: t2.micro no soporta EBS optimized — limitacion del tipo de instancia
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-ec2-windows-root-disk"
    })
  }

  # checkov:skip=CKV2_AWS_41: IAM role no requerido para esta instancia en entorno de hackathon

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-windows"
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

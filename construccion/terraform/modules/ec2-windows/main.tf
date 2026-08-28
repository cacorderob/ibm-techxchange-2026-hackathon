# =============================================================================
# Módulo: ec2-windows
# Descripción: Aprovisiona una instancia EC2 con Windows Server 2022 en AWS
# Recursos: aws_instance, aws_security_group, aws_key_pair, data aws_ami
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
# Key Pair: creado por Terraform usando la clave pública provista como variable
# La clave privada NUNCA se almacena en el repositorio ni en Terraform Cloud
# -----------------------------------------------------------------------------
resource "aws_key_pair" "ec2_keypair" {
  key_name   = "${var.project_name}-${var.environment}-keypair"
  public_key = var.public_key_content

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group: permite RDP (3389) solo desde el CIDR configurado
# No se abre a 0.0.0.0/0 — principio de mínimo privilegio
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${var.environment}-sg-ec2"
  description = "Security group para EC2 Windows - permite RDP restringido"
  vpc_id      = var.vpc_id

  # Regla de ingreso: RDP (3389) restringido al CIDR configurado por variable
  ingress {
    description = "RDP desde CIDR permitido"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
  }

  # Regla de egreso: todo el tráfico saliente permitido
  egress {
    description = "Todo el trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg-ec2"
  })
}

# -----------------------------------------------------------------------------
# Instancia EC2: Windows Server 2022, t2.micro, con IP pública dinámica
# La IP pública es asignada por AWS al momento del aprovisionamiento
# -----------------------------------------------------------------------------
resource "aws_instance" "windows" {
  ami                         = data.aws_ami.windows_server_2022.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ec2_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  # Disco raíz: gp3 para mejor rendimiento y costo
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-ec2-windows-root-disk"
    })
  }

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

# =============================================================================
# Outputs — Módulo ec2-windows
# =============================================================================

output "instance_id" {
  description = "ID de la instancia EC2 creada."
  value       = aws_instance.windows.id
}

output "instance_public_ip" {
  description = "IP pública de la instancia EC2, asignada dinámicamente por AWS al aprovisionar."
  value       = aws_instance.windows.public_ip
}

output "instance_private_ip" {
  description = "IP privada de la instancia EC2 dentro de la VPC."
  value       = aws_instance.windows.private_ip
}

output "security_group_id" {
  description = "ID del Security Group asociado a la instancia EC2."
  value       = aws_security_group.ec2_sg.id
}

output "security_group_name" {
  description = "Nombre del Security Group asociado a la instancia EC2."
  value       = aws_security_group.ec2_sg.name
}

output "key_pair_name" {
  description = "Nombre del Key Pair creado en AWS para la instancia EC2."
  value       = aws_key_pair.ec2_keypair.key_name
}

output "ami_id" {
  description = "ID de la AMI de Windows Server 2022 utilizada para la instancia."
  value       = data.aws_ami.windows_server_2022.id
}

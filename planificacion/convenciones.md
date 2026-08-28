# Convenciones del Proyecto

## Convenciones de nombrado de recursos AWS

### Patrón general

```
{proyecto}-{ambiente}-{tipo_recurso}-{sufijo_opcional}
```

### Ejemplos

| Recurso | Patrón | Ejemplo |
|---------|--------|---------|
| EC2 Instance | `{proyecto}-{ambiente}-ec2-windows` | `hackaton-dev-ec2-windows` |
| Security Group EC2 | `{proyecto}-{ambiente}-sg-ec2` | `hackaton-dev-sg-ec2` |
| RDS Instance | `{proyecto}-{ambiente}-rds-sqlserver` | `hackaton-dev-rds-sqlserver` |
| Security Group RDS | `{proyecto}-{ambiente}-sg-rds` | `hackaton-dev-sg-rds` |
| Key Pair | `{proyecto}-{ambiente}-keypair` | `hackaton-dev-keypair` |
| DB Subnet Group | `{proyecto}-{ambiente}-dbsubnetgroup` | `hackaton-dev-dbsubnetgroup` |

### Reglas de nombrado

- Usar **minúsculas** y **guiones** (`-`) como separador
- No usar guiones bajos (`_`) en nombres de recursos AWS
- No usar espacios ni caracteres especiales
- Máximo 63 caracteres para nombres de recursos AWS
- El nombre del proyecto viene de la variable `var.project_name`
- El ambiente viene de la variable `var.environment`

## Tags obligatorios en todos los recursos AWS

```hcl
tags = {
  Name        = "${var.project_name}-${var.environment}-{tipo}"
  Environment = var.environment
  Project     = var.project_name
  Owner       = var.owner
  ManagedBy   = "Terraform"
}
```

| Tag | Descripción | Ejemplo |
|-----|-------------|---------|
| `Name` | Identificador único del recurso | `hackaton-dev-ec2-windows` |
| `Environment` | Ambiente del recurso | `dev`, `staging`, `prod` |
| `Project` | Nombre del proyecto | `ibm-techxchange-2026` |
| `Owner` | Responsable del recurso | `cacorderob` |
| `ManagedBy` | Herramienta de gestión | `Terraform` (siempre este valor) |

## Estructura de archivos Terraform

```
construccion/terraform/
├── main.tf           ← Instanciación de módulos y recursos principales
├── variables.tf      ← Declaración de todas las variables del root module
├── outputs.tf        ← Outputs del root module
├── versions.tf       ← Versiones de Terraform, proveedores y backend cloud
├── terraform.tfvars.example  ← Ejemplo de variables (sin valores reales)
└── modules/
    ├── ec2-windows/
    │   ├── main.tf       ← Recursos: aws_instance, aws_security_group, data aws_ami, aws_key_pair
    │   ├── variables.tf  ← Variables del módulo
    │   └── outputs.tf    ← Outputs del módulo
    └── rds-sqlserver/
        ├── main.tf       ← Recursos: aws_db_instance, aws_db_subnet_group, aws_security_group
        ├── variables.tf  ← Variables del módulo
        └── outputs.tf    ← Outputs del módulo
```

## Estándares de código Terraform

### Archivos

- Un archivo `main.tf` por módulo con los recursos principales
- Un archivo `variables.tf` por módulo con todas las variables
- Un archivo `outputs.tf` por módulo con todos los outputs
- El `versions.tf` solo en el root module (no en módulos hijos)
- Separar recursos lógicamente con comentarios de sección

### Variables

```hcl
# ✅ Correcto — con descripción, tipo y default cuando aplique
variable "environment" {
  description = "Nombre del ambiente (ej: dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ✅ Correcto — variables sensibles marcadas
variable "db_password" {
  description = "Contraseña del administrador de la base de datos"
  type        = string
  sensitive   = true
}

# ❌ Incorrecto — sin descripción ni tipo
variable "env" {}
```

### Outputs

```hcl
# ✅ Correcto — con descripción y sensitive cuando aplique
output "instance_public_ip" {
  description = "IP pública de la instancia EC2 asignada por AWS"
  value       = aws_instance.windows.public_ip
}

output "db_endpoint" {
  description = "Endpoint de conexión a la base de datos RDS"
  value       = aws_db_instance.sqlserver.endpoint
  sensitive   = true
}
```

### Recursos

```hcl
# ✅ Correcto — con comentario descriptivo y tags completos
# Instancia EC2 Windows Server 2022
resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows_server_2022.id
  instance_type = var.instance_type

  tags = local.common_tags
}
```

### Locals

```hcl
# Usar locals para valores derivados o repetidos
locals {
  common_tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-windows"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}
```

## Convenciones de Git

### Política de ramas

| Rama | Propósito | Merge hacia |
|------|-----------|-------------|
| `main` | Código de producción/principal | — |
| `feature/{descripcion}` | Nuevas funcionalidades | `main` via PR |
| `fix/{descripcion}` | Correcciones de errores | `main` via PR |
| `docs/{descripcion}` | Solo cambios de documentación | `main` via PR |
| `refactor/{descripcion}` | Refactorizaciones sin cambio funcional | `main` via PR |

### Conventional Commits (en español)

```
{tipo}({alcance}): {descripción breve en imperativo}

{cuerpo opcional con más detalles}

{footer opcional: referencias a issues}
```

#### Tipos permitidos

| Tipo | Cuándo usarlo |
|------|---------------|
| `feat` | Nueva funcionalidad o recurso |
| `fix` | Corrección de error |
| `docs` | Solo cambios de documentación |
| `refactor` | Refactorización sin cambio funcional |
| `chore` | Tareas de mantenimiento (actualizar deps, etc.) |
| `ci` | Cambios en el pipeline CI/CD |
| `security` | Mejoras o correcciones de seguridad |

#### Ejemplos de commits

```bash
feat(terraform): agrega módulo EC2 Windows con AMI dinámica
feat(rds): agrega módulo RDS SQL Server Express con variables sensibles
docs(planificacion): agrega arquitectura y requerimientos del proyecto
ci(devsecops): configura pipeline con checkov y gitleaks
fix(ec2): corrige regla de security group para RDP
refactor(terraform): extrae tags comunes a locals
```

### Reglas de commits

- Descripción en **imperativo presente** (agrega, corrige, actualiza — no "agregado" ni "se agrega")
- Primera letra en **minúscula**
- Sin punto al final de la descripción
- Máximo 72 caracteres en la primera línea
- En **español latinoamericano**

## Convenciones de documentación

- Toda la documentación en **Markdown** (`.md`)
- Usar **tablas** para comparaciones y listas de atributos
- Usar **bloques de código** con el lenguaje especificado (` ```hcl `, ` ```bash `, etc.)
- Usar diagramas **Mermaid** para flujos y arquitecturas
- Encabezados en **Título de Caso** (primera letra mayúscula por palabra principal)
- Idioma: **español latinoamericano**

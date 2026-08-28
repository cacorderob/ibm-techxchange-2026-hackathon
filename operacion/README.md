# Etapa Operation — Documentación Operacional

## Descripción del proyecto

Este proyecto provisiona automáticamente una infraestructura básica en AWS mediante **Terraform**,
compuesta por una máquina virtual Windows Server 2022 y una base de datos SQL Server Express,
gestionada con un pipeline **DevSecOps** en GitHub Actions.

## Qué hace el proyecto

| Recurso | Descripción |
|---------|-------------|
| **EC2 Windows Server 2022** | Instancia `t2.micro` en `us-east-1` con IP pública dinámica, key pair gestionado por Terraform y acceso RDP restringido |
| **RDS SQL Server Express** | Instancia `db.t3.micro` en `us-east-1`, accesible solo desde la EC2, sin Multi-AZ, sin snapshot final |
| **Key Pair AWS** | Creado por Terraform usando la clave pública provista como variable sensible |
| **Security Groups** | SG-EC2 (RDP restringido) y SG-RDS (SQL Server solo desde EC2) |

## Infraestructura como código

- **Herramienta:** Terraform >= 1.5 con proveedor AWS `~> 5.0`
- **Backend:** Terraform Cloud — organización `GBM-HA-TEST`, proyecto `Carlos pruebas`, workspace `hackaton`
- **Módulos:** `ec2-windows` y `rds-sqlserver` (reutilizables y parametrizados)
- **Sin secretos en código:** Todas las credenciales gestionadas en Terraform Cloud

## Pipeline DevSecOps

El pipeline en GitHub Actions (`.github/workflows/devsecops.yml`) ejecuta:
1. Análisis SAST con `checkov`
2. Validación de formato y sintaxis de Terraform
3. Detección de secretos con `gitleaks`
4. Generación del plan de cambios
5. Gate de aprobación manual (environment `produccion`)
6. Apply automático tras aprobación

## Cómo desplegarlo

Ver [`guia_despliegue.md`](./guia_despliegue.md) para instrucciones paso a paso.

## Cómo configurar Terraform Cloud

Ver [`guia_terraform_cloud.md`](./guia_terraform_cloud.md) para crear y configurar el workspace `hackaton`.

## Cómo destruirlo

```bash
# Desde el directorio raíz del proyecto
cd construccion/terraform
terraform init
terraform destroy
```

O desde Terraform Cloud: workspace `hackaton` → **Actions** → **Start destroy plan**.

## Dependencias y requisitos previos

| Requisito | Descripción |
|-----------|-------------|
| Cuenta AWS | Con permisos IAM para EC2, RDS, VPC, Security Groups y Key Pairs |
| Terraform Cloud | Cuenta en `app.terraform.io`, organización `GBM-HA-TEST` |
| GitHub | Acceso al repositorio `cacorderob/ibm-techxchange-2026-hackathon` |
| Secrets GitHub | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_API_TOKEN` configurados |
| Variables Terraform Cloud | Ver tabla completa en `guia_terraform_cloud.md` |
| Clave SSH | Par de claves SSH generado localmente; clave pública lista para configurar |

## Documentos de esta etapa

| Documento | Descripción |
|-----------|-------------|
| [`guia_despliegue.md`](./guia_despliegue.md) | Instrucciones paso a paso para desplegar la infraestructura |
| [`guia_terraform_cloud.md`](./guia_terraform_cloud.md) | Configuración del workspace en Terraform Cloud |
| [`runbook.md`](./runbook.md) | Procedimientos operacionales: inicio, detención, troubleshooting |
| [`seguridad.md`](./seguridad.md) | Controles de seguridad y gestión de secretos |

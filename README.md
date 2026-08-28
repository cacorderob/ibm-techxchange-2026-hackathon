# 🚀 IBM TechXchange 2026 Hackathon — Infraestructura AWS con Terraform

[![DevSecOps Pipeline](https://github.com/cacorderob/ibm-techxchange-2026-hackathon/actions/workflows/devsecops.yml/badge.svg)](https://github.com/cacorderob/ibm-techxchange-2026-hackathon/actions/workflows/devsecops.yml)

## Descripción

Este repositorio contiene la infraestructura como código (IaC) para el hackathon IBM TechXchange 2026.
Provisiona automáticamente una máquina virtual Windows Server 2022 y una base de datos SQL Server en AWS,
utilizando **Terraform** con backend remoto en **Terraform Cloud**, un pipeline **DevSecOps** completo con
**GitHub Actions**, y documentación estructurada siguiendo el ciclo de vida del proyecto.

## Arquitectura

- **EC2:** Windows Server 2022, instancia `t2.micro`, región `us-east-1`
- **RDS:** SQL Server Express (`sqlserver-ex`), instancia `db.t3.micro`, región `us-east-1`
- **Backend:** Terraform Cloud — Organización `GBM-HA-TEST`, Proyecto `Carlos pruebas`, Workspace `hackaton`
- **Pipeline:** GitHub Actions con SAST (checkov), detección de secretos (gitleaks), gate de aprobación manual y apply automático

## Estructura del repositorio

```
/
├── .github/
│   └── workflows/
│       └── devsecops.yml          ← Pipeline DevSecOps (CI/CD)
├── planificacion/                 ← Etapa Inception: documentación de diseño
│   ├── README.md
│   ├── arquitectura.md
│   ├── requerimientos.md
│   ├── plan_devsecops.md
│   └── convenciones.md
├── construccion/                  ← Etapa Construction: código Terraform
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── terraform.tfvars.example
│       └── modules/
│           ├── ec2-windows/
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── outputs.tf
│           └── rds-sqlserver/
│               ├── main.tf
│               ├── variables.tf
│               └── outputs.tf
└── operacion/                     ← Etapa Operation: guías y runbooks
    ├── README.md
    ├── guia_despliegue.md
    ├── guia_terraform_cloud.md
    ├── runbook.md
    └── seguridad.md
```

## Ciclo de vida del proyecto

| Etapa | Carpeta | Descripción |
|-------|---------|-------------|
| **Inception** | [`/planificacion`](./planificacion/) | Arquitectura, requerimientos, plan DevSecOps y convenciones |
| **Construction** | [`/construccion`](./construccion/) | Código Terraform modular y pipeline CI/CD |
| **Operation** | [`/operacion`](./operacion/) | Guías de despliegue, Terraform Cloud y runbooks |

## Inicio rápido

1. Leer la [guía de despliegue](./operacion/guia_despliegue.md)
2. Configurar el workspace en Terraform Cloud siguiendo la [guía de Terraform Cloud](./operacion/guia_terraform_cloud.md)
3. Configurar los secrets en GitHub Actions (ver [plan DevSecOps](./planificacion/plan_devsecops.md))
4. Realizar un push a `main` para disparar el pipeline

## Seguridad

- ❌ **Ningún secreto, credencial o dato sensible está expuesto en el código**
- ✅ Todas las credenciales se gestionan mediante Terraform Cloud (variables sensibles) y GitHub Secrets
- ✅ Pipeline con análisis SAST, detección de secretos y gate de aprobación manual antes del apply

## Requisitos previos

- Cuenta AWS con permisos para crear EC2, RDS, VPC, Security Groups y Key Pairs
- Cuenta en [Terraform Cloud](https://app.terraform.io/) con organización `GBM-HA-TEST`
- Repositorio GitHub conectado como VCS Provider en Terraform Cloud
- Secrets configurados en GitHub Actions: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_API_TOKEN`

## Contribución

Ver las [convenciones del proyecto](./planificacion/convenciones.md) para estándares de código,
nombrado de recursos y política de ramas Git.

---

*Proyecto desarrollado para IBM TechXchange 2026 Hackathon*

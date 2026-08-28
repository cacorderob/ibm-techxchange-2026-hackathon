# Etapa Inception — Planificación del Proyecto

## Descripción general

Este directorio contiene toda la documentación de la etapa de **Inception** del proyecto de infraestructura
para el hackathon IBM TechXchange 2026. Aquí se definen los objetivos, arquitectura, requerimientos y
lineamientos técnicos que guían las etapas de construcción y operación.

## Objetivo del proyecto

Aprovisionar de manera automatizada, segura y reproducible una infraestructura básica en AWS compuesta por:

- Una **máquina virtual Windows Server 2022** (EC2 `t2.micro`) en la región `us-east-1`
- Una **base de datos SQL Server Express** (RDS `db.t3.micro`) en la misma región
- Todo gestionado mediante **Terraform** con backend remoto en **Terraform Cloud**
- Integrado con un pipeline **DevSecOps** en **GitHub Actions**

## Alcance

### Dentro del alcance
- Aprovisionamiento de EC2 Windows Server 2022 con tipo `t2.micro`
- Aprovisionamiento de RDS SQL Server Express con tipo `db.t3.micro`
- Security Groups con reglas de mínimo privilegio
- Key pair gestionado por Terraform
- Backend remoto en Terraform Cloud (organización `GBM-HA-TEST`, workspace `hackaton`)
- Pipeline DevSecOps con análisis de seguridad, validación y gate de aprobación manual
- Documentación completa de arquitectura, operación y seguridad

### Fuera del alcance
- Configuración interna del sistema operativo Windows
- Instalación de software adicional en la VM
- Alta disponibilidad o Multi-AZ (entorno de prueba/hackathon)
- Ambientes múltiples (solo se aprovisiona un ambiente)
- Dominio o DNS personalizado

## Stakeholders

| Rol | Responsabilidad |
|-----|-----------------|
| **Carlos Cordero (cacorderob)** | Propietario del proyecto, responsable del repositorio |
| **Equipo de Hackathon** | Usuarios de la infraestructura |
| **Terraform Cloud (GBM-HA-TEST)** | Plataforma de ejecución y estado remoto |
| **AWS** | Proveedor de infraestructura cloud |

## Justificación técnica

| Decisión | Justificación |
|----------|---------------|
| **Terraform** | Estándar de la industria para IaC, soporte multi-cloud, módulos reutilizables |
| **Terraform Cloud** | Backend remoto seguro, gestión de estado, ejecución controlada, variables sensibles |
| **GitHub Actions** | CI/CD nativo en GitHub, integración directa con el repositorio |
| **Windows Server 2022** | Requerimiento del proyecto para VM Windows |
| **SQL Server Express (RDS)** | Capa mínima de costo en AWS para SQL Server, sin licencia adicional |
| **t2.micro / db.t3.micro** | Instancias mínimas para entorno de prueba/hackathon |
| **Módulos Terraform** | Reutilización, separación de responsabilidades, mantenibilidad |

## Documentos de esta etapa

| Documento | Descripción |
|-----------|-------------|
| [`arquitectura.md`](./arquitectura.md) | Diagrama y descripción de la arquitectura de infraestructura |
| [`requerimientos.md`](./requerimientos.md) | Requerimientos funcionales y no funcionales detallados |
| [`plan_devsecops.md`](./plan_devsecops.md) | Plan del pipeline DevSecOps: etapas, herramientas y controles |
| [`convenciones.md`](./convenciones.md) | Convenciones de código, nombrado y políticas de ramas |

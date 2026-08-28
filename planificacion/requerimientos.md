# Requerimientos del Proyecto

## Requerimientos funcionales

### RF-01 — Máquina virtual Windows Server en AWS

| Atributo | Especificación |
|----------|----------------|
| **Proveedor cloud** | Amazon Web Services (AWS) |
| **Servicio** | Amazon EC2 |
| **Sistema operativo** | Windows Server 2022 (AMI oficial de Amazon) |
| **Tipo de instancia** | `t2.micro` |
| **Región** | `us-east-1` (Norte de Virginia) |
| **IP pública** | Asignada dinámicamente por AWS al momento del aprovisionamiento |
| **Key pair** | Creado por Terraform como recurso `aws_key_pair`; la clave pública se provee mediante variable sensible |
| **Acceso remoto** | RDP (puerto 3389) restringido al CIDR especificado en variable de configuración |
| **AMI** | Buscada dinámicamente usando `data "aws_ami"` — siempre la más reciente de Windows Server 2022 del owner `amazon` |

### RF-02 — Base de datos SQL Server en AWS

| Atributo | Especificación |
|----------|----------------|
| **Proveedor cloud** | Amazon Web Services (AWS) |
| **Servicio** | Amazon RDS |
| **Motor** | `sqlserver-ex` (SQL Server Express Edition) |
| **Versión del motor** | `15.00` (SQL Server 2019 Express) |
| **Tipo de instancia** | `db.t3.micro` |
| **Región** | `us-east-1` (Norte de Virginia) |
| **Licencia** | `license-included` (requerido por AWS RDS para SQL Server) |
| **Multi-AZ** | Deshabilitado (entorno de prueba/hackathon) |
| **Snapshot final** | Deshabilitado (`skip_final_snapshot = true`) |
| **Acceso** | Puerto 1433, restringido al Security Group de la EC2 |
| **Credenciales** | Usuario y contraseña administradores provistos como variables sensibles, nunca en código |

### RF-03 — Gestión de infraestructura como código

| Atributo | Especificación |
|----------|----------------|
| **Herramienta IaC** | Terraform >= 1.5 |
| **Proveedor AWS** | `hashicorp/aws ~> 5.0` |
| **Estructura** | Módulos reutilizables: `ec2-windows` y `rds-sqlserver` |
| **Backend** | Terraform Cloud — organización `GBM-HA-TEST`, workspace `hackaton` |
| **Estado remoto** | Gestionado por Terraform Cloud (nunca local) |

### RF-04 — Pipeline de integración y despliegue continuo

| Atributo | Especificación |
|----------|----------------|
| **Plataforma CI/CD** | GitHub Actions |
| **Disparadores** | `push` a `main`, `pull_request` a `main` |
| **Análisis SAST** | `checkov` sobre el directorio `construccion/terraform` |
| **Detección de secretos** | `gitleaks` sobre el repositorio completo |
| **Validación de código** | `terraform fmt -check` y `terraform validate` |
| **Plan** | `terraform plan` autenticado con Terraform Cloud |
| **Gate de aprobación** | Aprobación manual requerida antes del apply (environment `produccion`) |
| **Apply** | `terraform apply -auto-approve` solo en rama `main` tras aprobación |

---

## Requerimientos no funcionales

### RNF-01 — Seguridad

| ID | Requerimiento |
|----|---------------|
| RNF-01.1 | **Cero secretos en código:** Ninguna credencial, token, contraseña, access key ni secret key debe estar presente en ningún archivo del repositorio |
| RNF-01.2 | **Variables sensibles:** Las credenciales AWS (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) se configuran como variables de entorno en Terraform Cloud, marcadas como sensibles |
| RNF-01.3 | **Credenciales DB:** Usuario y contraseña de la base de datos se configuran como variables de Terraform en Terraform Cloud, con `sensitive = true` |
| RNF-01.4 | **Clave pública EC2:** El contenido de la clave pública para el key pair se configura como variable de Terraform en Terraform Cloud, con `sensitive = true` |
| RNF-01.5 | **RDP restringido:** El puerto 3389 (RDP) no debe estar abierto a `0.0.0.0/0`; debe restringirse al CIDR configurado en variable |
| RNF-01.6 | **SQL Server restringido:** El puerto 1433 solo debe ser accesible desde el Security Group de la EC2, no desde internet |
| RNF-01.7 | **SAST en pipeline:** Todo código Terraform debe pasar análisis de seguridad con `checkov` antes de ejecutar plan o apply |
| RNF-01.8 | **Detección de secretos:** El pipeline debe verificar con `gitleaks` que no existen secretos expuestos accidentalmente |

### RNF-02 — Mantenibilidad

| ID | Requerimiento |
|----|---------------|
| RNF-02.1 | El código Terraform debe organizarse en módulos reutilizables siguiendo el principio DRY |
| RNF-02.2 | Todos los recursos deben tener tags obligatorios: `Name`, `Environment`, `Project`, `Owner`, `ManagedBy = "Terraform"` |
| RNF-02.3 | Todas las variables deben tener descripción, tipo y valor por defecto cuando aplique |
| RNF-02.4 | Los outputs deben documentar qué exponen y marcar como `sensitive = true` los que contengan datos sensibles |
| RNF-02.5 | Los archivos Terraform deben cumplir el formato estándar (`terraform fmt`) |
| RNF-02.6 | Los mensajes de commit deben seguir la convención Conventional Commits en español |

### RNF-03 — Reproducibilidad

| ID | Requerimiento |
|----|---------------|
| RNF-03.1 | Las versiones del proveedor AWS y Terraform deben estar fijadas con rangos específicos en `versions.tf` |
| RNF-03.2 | La AMI de Windows Server debe buscarse dinámicamente (siempre la más reciente); no debe hardcodearse el ID de la AMI |
| RNF-03.3 | La infraestructura debe poder destruirse completamente con `terraform destroy` sin intervención manual |
| RNF-03.4 | El archivo `terraform.tfvars.example` debe documentar todas las variables con valores ficticios de ejemplo |

### RNF-04 — Documentación

| ID | Requerimiento |
|----|---------------|
| RNF-04.1 | Todos los artefactos de la etapa Inception deben estar en la carpeta `/planificacion` |
| RNF-04.2 | Todo el código Terraform y el pipeline deben estar en la carpeta `/construccion` |
| RNF-04.3 | Toda la documentación operacional debe estar en la carpeta `/operacion` |
| RNF-04.4 | La documentación debe estar en español latinoamericano |
| RNF-04.5 | La guía de Terraform Cloud debe incluir la lista exacta de variables a crear, sus nombres, tipos y sensibilidad |

### RNF-05 — Portabilidad

| ID | Requerimiento |
|----|---------------|
| RNF-05.1 | El código no debe depender de configuraciones locales del desarrollador |
| RNF-05.2 | Cualquier persona con acceso al repositorio y las credenciales correctas debe poder desplegar la infraestructura |
| RNF-05.3 | El pipeline debe funcionar en el runner estándar de GitHub Actions (`ubuntu-latest`) |

---

## Restricciones del proyecto

| Restricción | Descripción |
|-------------|-------------|
| **Región** | Todos los recursos deben crearse en `us-east-1` |
| **Tipo de instancia EC2** | Debe ser exactamente `t2.micro` |
| **Motor RDS** | Debe ser `sqlserver-ex` (SQL Server Express) o el mínimo disponible |
| **Backend** | Debe usar Terraform Cloud como backend remoto, no backend local ni S3 |
| **Costo** | Instancias mínimas para entorno de hackathon/prueba |
| **Idioma** | Toda documentación, comentarios y commits en español latinoamericano |

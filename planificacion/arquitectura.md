# Arquitectura de Infraestructura

## Diagrama de arquitectura

```mermaid
graph TB
    subgraph GitHub["GitHub — cacorderob/ibm-techxchange-2026-hackathon"]
        REPO[Repositorio Git\nrama: main]
        GA[GitHub Actions\nPipeline DevSecOps]
    end

    subgraph TFC["Terraform Cloud — GBM-HA-TEST / Carlos pruebas / hackaton"]
        WS[Workspace: hackaton\nEstado remoto TF]
        VARS[Variables sensibles\nAWS Keys, DB Credentials]
    end

    subgraph AWS["AWS — us-east-1"]
        subgraph VPC["VPC por defecto"]
            subgraph SN["Subnet pública"]
                EC2[EC2\nWindows Server 2022\nt2.micro]
                SG_EC2[Security Group EC2\nRDP 3389 restringido]
            end
            subgraph SNP["Subnet privada / grupo"]
                RDS[RDS SQL Server Express\ndb.t3.micro]
                SG_RDS[Security Group RDS\nAcceso solo desde EC2]
            end
            KP[Key Pair\naws_key_pair]
        end
    end

    REPO -->|push/PR a main| GA
    GA -->|TF_API_TOKEN| TFC
    TFC -->|terraform plan/apply| AWS
    VARS -->|inyección segura| WS
    EC2 --- SG_EC2
    RDS --- SG_RDS
    SG_EC2 -->|ingress CIDR permitido| EC2
    SG_RDS -->|ingress desde SG_EC2| RDS
    KP --> EC2
```

## Descripción de componentes

### GitHub Actions (Pipeline DevSecOps)
- Disparado por `push` y `pull_request` a la rama `main`
- Ejecuta análisis de seguridad, validación de código Terraform y detección de secretos
- Requiere aprobación manual antes del apply
- Se autentica con Terraform Cloud mediante `TF_API_TOKEN`

### Terraform Cloud
- **Organización:** `GBM-HA-TEST`
- **Proyecto:** `Carlos pruebas`
- **Workspace:** `hackaton`
- Almacena el estado remoto de Terraform de forma segura
- Gestiona todas las variables sensibles (credenciales AWS, contraseñas DB)
- Conectado al VCS Provider del repositorio GitHub

### EC2 — Windows Server 2022

| Atributo | Valor |
|----------|-------|
| Sistema operativo | Windows Server 2022 |
| Tipo de instancia | `t2.micro` |
| Región | `us-east-1` |
| AMI | Dinámica (última disponible de `amazon`) |
| IP pública | Asignada dinámicamente por AWS al aprovisionar |
| Key pair | Creado por Terraform (`aws_key_pair`) |
| Security Group | RDP (3389) restringido al CIDR configurado |

### RDS — SQL Server Express

| Atributo | Valor |
|----------|-------|
| Motor | `sqlserver-ex` (SQL Server Express) |
| Versión | `15.00` (SQL Server 2019) |
| Tipo de instancia | `db.t3.micro` |
| Región | `us-east-1` |
| Multi-AZ | Deshabilitado (entorno de prueba) |
| Licencia | `license-included` |
| Snapshot final | Deshabilitado (`skip_final_snapshot = true`) |
| Security Group | Acceso restringido al Security Group de EC2 |

### Security Groups

#### SG-EC2 (ec2-windows-sg)
| Tipo | Protocolo | Puerto | Origen |
|------|-----------|--------|--------|
| Ingress | TCP | 3389 (RDP) | CIDR configurado en variable |
| Egress | All | All | `0.0.0.0/0` |

#### SG-RDS (rds-sqlserver-sg)
| Tipo | Protocolo | Puerto | Origen |
|------|-----------|--------|--------|
| Ingress | TCP | 1433 (SQL Server) | Security Group de EC2 |
| Egress | All | All | `0.0.0.0/0` |

## Flujo de aprovisionamiento

```mermaid
sequenceDiagram
    actor Dev as Desarrollador
    participant GH as GitHub
    participant GA as GitHub Actions
    participant TFC as Terraform Cloud
    participant AWS as AWS us-east-1

    Dev->>GH: git push main
    GH->>GA: Disparar workflow devsecops.yml
    GA->>GA: Checkout del código
    GA->>GA: checkov (SAST)
    GA->>GA: terraform fmt -check
    GA->>GA: terraform validate
    GA->>GA: gitleaks (detección secretos)
    GA->>TFC: terraform plan
    TFC->>AWS: Consulta estado actual
    AWS-->>TFC: Estado actual
    TFC-->>GA: Plan generado
    GA->>Dev: Solicitar aprobación manual
    Dev->>GA: Aprobar apply
    GA->>TFC: terraform apply
    TFC->>AWS: Crear EC2 + RDS + SGs + Key Pair
    AWS-->>TFC: Recursos creados
    TFC-->>GA: Apply exitoso
    GA->>Dev: Notificación de éxito
```

## Consideraciones de red

- Se utiliza la **VPC por defecto** de AWS en `us-east-1` para simplicidad del entorno de hackathon
- La EC2 recibe una IP pública dinámica asignada por AWS
- La RDS se ubica en un DB Subnet Group que abarca múltiples zonas de disponibilidad
- La comunicación entre EC2 y RDS se restringe mediante Security Groups (no IP hardcodeada)

## Consideraciones de seguridad

- Las credenciales AWS nunca están en el código; se inyectan desde Terraform Cloud (variables de entorno)
- La contraseña de la base de datos es una variable `sensitive = true` en Terraform Cloud
- El RDP (3389) no está abierto a `0.0.0.0/0`; se restringe al CIDR configurado por variable
- El puerto de SQL Server (1433) solo es accesible desde el Security Group de la EC2
- El pipeline verifica la ausencia de secretos expuestos con `gitleaks` antes de ejecutar cualquier apply

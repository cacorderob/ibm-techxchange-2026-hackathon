# Plan DevSecOps

## Visión general

El pipeline DevSecOps integra seguridad en cada etapa del ciclo de desarrollo, desde el análisis estático
del código hasta el despliegue en AWS, garantizando que ningún código inseguro o con secretos expuestos
llegue a producción.

## Herramientas utilizadas

| Herramienta | Propósito | Etapa |
|-------------|-----------|-------|
| **checkov** | Análisis estático de seguridad (SAST) en código Terraform | Pre-plan |
| **gitleaks** | Detección de secretos y credenciales expuestas en el repositorio | Pre-plan |
| **terraform fmt** | Validación de formato estándar del código Terraform | Pre-plan |
| **terraform validate** | Validación de sintaxis y consistencia del código Terraform | Pre-plan |
| **terraform plan** | Generación del plan de cambios de infraestructura | Plan |
| **terraform apply** | Aplicación de cambios en AWS | Apply |
| **GitHub Environments** | Gate de aprobación manual antes del apply | Aprobación |

## Etapas del pipeline

```
Push/PR a main
     │
     ▼
┌─────────────┐
│  1. Checkout │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│  2. SAST/checkov  │ ──── FALLA → bloquea pipeline
└──────┬───────────┘
       │
       ▼
┌─────────────────────┐
│  3. terraform fmt   │ ──── FALLA → bloquea pipeline
└──────┬──────────────┘
       │
       ▼
┌──────────────────────────┐
│  4. terraform validate   │ ──── FALLA → bloquea pipeline
└──────┬───────────────────┘
       │
       ▼
┌────────────────┐
│  5. gitleaks   │ ──── FALLA → bloquea pipeline
└──────┬─────────┘
       │
       ▼
┌──────────────────────┐
│  6. terraform plan   │ ──── FALLA → bloquea pipeline
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────┐
│  7. Gate de aprobación   │ ◄── Aprobación manual requerida
│     (environment:        │
│      produccion)         │
└──────┬───────────────────┘
       │ Aprobado
       ▼
┌────────────────────────────────┐
│  8. terraform apply            │ ──── Solo en rama main
│     (solo si aprobado + main)  │
└──────┬─────────────────────────┘
       │
       ▼
┌──────────────────────┐
│  9. Notificación     │
│     (éxito/fallo)    │
└──────────────────────┘
```

## Descripción detallada de cada etapa

### Etapa 1 — Checkout
- **Acción:** `actions/checkout@v4` con historial completo (`fetch-depth: 0`)
- **Motivo:** El historial completo es necesario para que gitleaks analice todos los commits

### Etapa 2 — SAST con checkov
- **Herramienta:** `checkov` (Bridgecrew/Palo Alto)
- **Directorio analizado:** `construccion/terraform`
- **Qué detecta:** Configuraciones inseguras de infraestructura (SGs abiertos, cifrado deshabilitado, etc.)
- **Gate:** El pipeline falla si se encuentran vulnerabilidades de severidad alta o crítica

### Etapa 3 — Validación de formato (terraform fmt)
- **Comando:** `terraform fmt -check -recursive`
- **Directorio:** `construccion/terraform`
- **Gate:** El pipeline falla si el código no cumple el formato estándar de Terraform

### Etapa 4 — Validación de sintaxis (terraform validate)
- **Comando:** `terraform validate`
- **Directorio:** `construccion/terraform`
- **Gate:** El pipeline falla si hay errores de sintaxis o configuración inválida

### Etapa 5 — Detección de secretos (gitleaks)
- **Herramienta:** `gitleaks` (detección de secretos con reglas predefinidas)
- **Alcance:** Repositorio completo (todos los archivos y commits)
- **Gate:** El pipeline falla si se detecta cualquier secreto o credencial expuesta

### Etapa 6 — Terraform Plan
- **Comando:** `terraform plan`
- **Autenticación:** `TF_API_TOKEN` (secret de GitHub Actions) para Terraform Cloud
- **Credenciales AWS:** `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` (secrets de GitHub Actions)
- **Output:** Plan guardado para revisión en los logs del workflow

### Etapa 7 — Gate de aprobación manual
- **Mecanismo:** GitHub Environment `produccion` con regla de protección
- **Requisito:** Al menos un revisor debe aprobar antes de continuar al apply
- **Tiempo máximo de espera:** Configurable en la configuración del environment (recomendado: 1 hora)

### Etapa 8 — Terraform Apply
- **Comando:** `terraform apply -auto-approve`
- **Condición:** Solo se ejecuta si la rama es `main` Y el gate fue aprobado
- **Autenticación:** Mismos secrets que el plan

### Etapa 9 — Notificación
- **Mecanismo:** GitHub Actions Job Summary
- **Contenido:** Estado del apply (éxito/fallo), outputs de Terraform (IP pública, endpoint RDS)

## Gestión de secretos

### GitHub Actions Secrets (configurar en el repositorio)

| Secret | Descripción | Cómo obtenerlo |
|--------|-------------|----------------|
| `AWS_ACCESS_KEY_ID` | Clave de acceso AWS | IAM Console → Access Keys |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS | IAM Console → Access Keys |
| `TF_API_TOKEN` | Token de Terraform Cloud | app.terraform.io → User Settings → Tokens |

### Terraform Cloud Variables (configurar en workspace `hackaton`)

| Variable | Tipo | Sensible | Descripción |
|----------|------|----------|-------------|
| `AWS_ACCESS_KEY_ID` | Environment | ✅ | Clave de acceso AWS |
| `AWS_SECRET_ACCESS_KEY` | Environment | ✅ | Clave secreta AWS |
| `TF_VAR_db_username` | Terraform | ✅ | Usuario administrador RDS |
| `TF_VAR_db_password` | Terraform | ✅ | Contraseña administrador RDS |
| `TF_VAR_public_key_content` | Terraform | ✅ | Clave pública SSH para key pair EC2 |
| `TF_VAR_allowed_rdp_cidr` | Terraform | ❌ | CIDR permitido para RDP |
| `TF_VAR_environment` | Terraform | ❌ | Nombre del ambiente |
| `TF_VAR_project_name` | Terraform | ❌ | Nombre del proyecto |
| `TF_VAR_owner` | Terraform | ❌ | Responsable del recurso |

## Política de ramas

| Rama | Descripción | Protección |
|------|-------------|------------|
| `main` | Rama principal de producción | Requiere PR + aprobación |
| `feature/*` | Nuevas funcionalidades | Sin protección |
| `fix/*` | Correcciones | Sin protección |
| `docs/*` | Solo documentación | Sin protección |

## Controles de seguridad adicionales

- **Branch protection en `main`:** Requiere pull request para mergear, no permite force push
- **Revisión de código:** Al menos un revisor requerido para mergear a `main`
- **CODEOWNERS:** Definir propietarios de código para revisiones automáticas
- **Dependabot:** Habilitar para actualizaciones automáticas de Actions y dependencias

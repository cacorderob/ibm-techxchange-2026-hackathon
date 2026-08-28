# Controles de Seguridad

## Resumen de controles implementados

| Control | Herramienta/Mecanismo | Estado |
|---------|-----------------------|--------|
| Cero secretos en código | Revisión manual + gitleaks | ✅ Implementado |
| Análisis SAST de IaC | checkov | ✅ Implementado |
| Detección de secretos en historial | gitleaks | ✅ Implementado |
| Credenciales AWS fuera del código | Terraform Cloud env vars | ✅ Implementado |
| Contraseña DB como variable sensible | Terraform Cloud + `sensitive=true` | ✅ Implementado |
| RDP no abierto a 0.0.0.0/0 | Security Group + validación en variable | ✅ Implementado |
| SQL Server no accesible desde internet | Security Group con origen en SG de EC2 | ✅ Implementado |
| Gate de aprobación manual | GitHub Environment `produccion` | ✅ Implementado |
| Cifrado de almacenamiento RDS | `storage_encrypted = true` | ✅ Implementado |
| Apply solo en rama main | Condición en GitHub Actions | ✅ Implementado |
| Versiones de proveedor fijadas | `versions.tf` con rangos específicos | ✅ Implementado |

---

## Gestión de secretos

### Principios aplicados

1. **Cero secretos en código:** Ningún secreto, credencial, token, contraseña o clave de acceso
   está presente en ningún archivo del repositorio. Esto incluye código Terraform, YAML de pipelines,
   documentación y archivos de ejemplo.

2. **Variables sensibles en Terraform Cloud:** Las credenciales AWS y las contraseñas de base de datos
   se almacenan como variables de tipo `sensitive` en el workspace `hackaton` de Terraform Cloud.
   Terraform Cloud cifra estos valores en reposo y los inyecta de forma segura durante la ejecución.

3. **Secrets de GitHub Actions:** El token de Terraform Cloud (`TF_API_TOKEN`) y las credenciales AWS
   se almacenan como `Repository secrets` en GitHub Actions, nunca en el código del workflow.

4. **Outputs sensibles:** Los outputs de Terraform que contienen información sensible (endpoint de RDS,
   dirección de la base de datos) están marcados con `sensitive = true`, lo que evita que se muestren
   en los logs del pipeline.

### Flujo de secretos

```
GitHub Actions           Terraform Cloud          AWS
    │                         │                    │
    │ TF_API_TOKEN ──────────►│                    │
    │                         │ AWS_ACCESS_KEY_ID  │
    │                         │ AWS_SECRET_ACCESS ─►│
    │                         │ _KEY               │
    │                         │                    │ Crea recursos
    │                         │◄───────────────────│ con credenciales
    │                         │  outputs (some      │ inyectadas
    │◄────────────────────────│  sensitive)         │
```

---

## Controles de red

### Security Group EC2 — `{proyecto}-{ambiente}-sg-ec2`

| Dirección | Protocolo | Puerto | Origen | Justificación |
|-----------|-----------|--------|--------|---------------|
| Ingress | TCP | 3389 (RDP) | CIDR configurado por variable | Acceso remoto restringido a IPs autorizadas |
| Egress | Todos | Todos | 0.0.0.0/0 | Permite que la instancia acceda a internet para actualizaciones |

**Control adicional:** La variable `allowed_rdp_cidr` tiene una validación en Terraform que rechaza
el valor `0.0.0.0/0`, previniendo accidentalmente abrir el RDP a todo internet.

### Security Group RDS — `{proyecto}-{ambiente}-sg-rds`

| Dirección | Protocolo | Puerto | Origen | Justificación |
|-----------|-----------|--------|--------|---------------|
| Ingress | TCP | 1433 (SQL Server) | Security Group de EC2 | Solo la EC2 puede conectarse a la RDS |
| Egress | Todos | Todos | 0.0.0.0/0 | Estándar para tráfico saliente de RDS |

**Control adicional:** La RDS no es `publicly_accessible`, lo que significa que no tiene endpoint
público; solo es accesible desde dentro de la VPC.

---

## Controles de infraestructura

### Cifrado en reposo — RDS

La instancia RDS tiene `storage_encrypted = true`, lo que cifra todos los datos almacenados en disco
utilizando AWS KMS con la clave administrada por AWS.

### Control de acceso — EC2

- El acceso a la instancia EC2 requiere la clave privada del key pair creado por Terraform
- La clave privada nunca se almacena en el repositorio ni en Terraform Cloud
- El usuario es responsable de custodiar la clave privada de forma segura

### Control de versiones — Terraform

Las versiones del proveedor AWS y de Terraform están fijadas en `versions.tf`:
- Terraform: `>= 1.5`
- AWS Provider: `~> 5.0`

Esto previene actualizaciones no controladas que puedan introducir cambios disruptivos.

---

## Pipeline de seguridad — Detalle de controles

### checkov (SAST)

checkov analiza el código Terraform en busca de:
- Security Groups abiertos a `0.0.0.0/0`
- Instancias RDS sin cifrado
- Recursos sin tags
- Configuraciones inseguras de IAM
- Falta de logging y monitoreo

**Configuración:** Se ejecuta sobre `construccion/terraform` con framework `terraform`.
El pipeline falla si se detectan issues de severidad alta o crítica.

### gitleaks (Detección de secretos)

gitleaks analiza:
- Todo el historial de commits del repositorio
- Todos los archivos actuales
- Patrones conocidos de secretos: AWS keys, tokens, contraseñas, claves privadas

**Configuración:** Se ejecuta con `fetch-depth: 0` para analizar el historial completo.
El pipeline falla si se detecta cualquier secreto.

### Gate de aprobación manual

El environment `produccion` en GitHub requiere aprobación manual de un revisor designado
antes de ejecutar `terraform apply`. Esto garantiza que:
- Un humano revisa el plan de cambios antes del apply
- Se previenen deploys accidentales o no autorizados
- Se mantiene un registro de auditoría de quién aprobó cada cambio

---

## Recomendaciones de hardening adicional

Las siguientes recomendaciones no están implementadas en el alcance actual del hackathon,
pero deberían considerarse para un ambiente de producción:

### Red
- [ ] Usar una VPC dedicada en lugar de la VPC por defecto
- [ ] Poner la EC2 en una subnet privada y acceder via VPN o bastión host en lugar de RDP directo
- [ ] Habilitar VPC Flow Logs para auditoría de tráfico de red
- [ ] Configurar AWS WAF si la EC2 expone servicios web

### Acceso
- [ ] Usar AWS Session Manager (SSM) en lugar de RDP para acceso sin exposición de puertos
- [ ] Implementar MFA para el acceso a la consola AWS
- [ ] Usar roles IAM con mínimo privilegio en lugar de credenciales de usuario IAM
- [ ] Habilitar AWS CloudTrail para auditoría de todas las acciones en la cuenta

### Base de datos
- [ ] Habilitar Multi-AZ para alta disponibilidad en producción
- [ ] Configurar backups automáticos (`backup_retention_period > 0`)
- [ ] Habilitar `deletion_protection = true` en producción
- [ ] Configurar grupos de parámetros personalizados para hardening de SQL Server
- [ ] Habilitar Enhanced Monitoring y Performance Insights

### Gestión de secretos
- [ ] Migrar las credenciales de RDS a AWS Secrets Manager con rotación automática
- [ ] Usar AWS KMS con claves propias (CMK) en lugar de claves administradas por AWS
- [ ] Implementar AWS IAM roles para que las aplicaciones accedan a la RDS sin contraseñas

### Monitoreo
- [ ] Configurar AWS CloudWatch Alarms para CPU, memoria y espacio en disco
- [ ] Configurar alertas de costos en AWS Budgets
- [ ] Implementar AWS Config Rules para detectar desvíos de configuración
- [ ] Habilitar Amazon GuardDuty para detección de amenazas

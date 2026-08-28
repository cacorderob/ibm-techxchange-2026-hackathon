# Runbook Operacional

## Información del sistema

| Dato | Valor |
|------|-------|
| **Proyecto** | IBM TechXchange 2026 Hackathon |
| **Repositorio** | `cacorderob/ibm-techxchange-2026-hackathon` |
| **Workspace TF** | `GBM-HA-TEST / Carlos pruebas / hackaton` |
| **Región AWS** | `us-east-1` |
| **Recursos** | EC2 Windows Server 2022 (`t2.micro`) + RDS SQL Server Express (`db.t3.micro`) |

---

## Procedimientos de inicio y detención

### Iniciar la instancia EC2 (si está detenida)

```bash
# Via AWS CLI
aws ec2 start-instances \
  --instance-ids <INSTANCE_ID> \
  --region us-east-1

# Verificar estado
aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].State.Name' \
  --region us-east-1
```

Desde la consola AWS: **EC2** → **Instances** → seleccionar instancia → **Instance state** → **Start instance**

> **Nota:** Al reiniciar la instancia EC2, AWS puede asignar una nueva IP pública (ya que la IP es dinámica).
> Verifica la nueva IP en la consola AWS o en los outputs de Terraform.

### Detener la instancia EC2 (sin destruirla)

```bash
# Via AWS CLI
aws ec2 stop-instances \
  --instance-ids <INSTANCE_ID> \
  --region us-east-1
```

Desde la consola AWS: **EC2** → **Instances** → seleccionar instancia → **Instance state** → **Stop instance**

> **Nota:** Detener la EC2 NO afecta a la RDS. La RDS continúa facturando aunque la EC2 esté detenida.

### Iniciar/Detener la instancia RDS

```bash
# Iniciar RDS
aws rds start-db-instance \
  --db-instance-identifier ibm-techxchange-2026-hackaton-rds-sqlserver \
  --region us-east-1

# Detener RDS (máximo 7 días, luego se reinicia automáticamente)
aws rds stop-db-instance \
  --db-instance-identifier ibm-techxchange-2026-hackaton-rds-sqlserver \
  --region us-east-1
```

---

## Procedimientos de troubleshooting

### Problema: El pipeline falla en la etapa de checkov

**Síntoma:** El job `seguridad-y-validacion` falla con errores de checkov.

**Diagnóstico:**
```bash
# Ejecutar checkov localmente para ver los errores detallados
pip install checkov
checkov -d construccion/terraform --framework terraform
```

**Solución:** Revisar los errores reportados por checkov y corregir la configuración insegura en el
código Terraform. Si es un falso positivo documentado, agregar la excepción con `# checkov:skip=CKV_XXX:Razón`.

---

### Problema: El pipeline falla en la etapa de gitleaks

**Síntoma:** El job `seguridad-y-validacion` falla indicando secretos detectados.

**Diagnóstico:**
```bash
# Ejecutar gitleaks localmente
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path -v
```

**Solución:**
1. Identificar el archivo y línea donde se detectó el secreto
2. Eliminar el secreto del archivo y del historial de Git
3. Si es un falso positivo, crear un archivo `.gitleaks.toml` con la regla de excepción
4. Forzar un nuevo commit limpio

---

### Problema: Terraform plan falla con error de autenticación AWS

**Síntoma:** Error `NoCredentialProviders` o `InvalidClientTokenId` durante el plan.

**Solución:**
1. Verificar que las variables de entorno `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` están configuradas en el workspace de Terraform Cloud
2. Verificar que las credenciales AWS no están expiradas (las credenciales temporales de STS tienen tiempo de expiración)
3. Verificar que el usuario IAM tiene los permisos necesarios para EC2 y RDS

---

### Problema: El apply falla con error de RDS — versión de motor no disponible

**Síntoma:** Error `InvalidParameterValue: Cannot find version 15.00.4153.1.v1 for sqlserver-ex`.

**Solución:**
```bash
# Listar versiones disponibles de SQL Server Express en us-east-1
aws rds describe-db-engine-versions \
  --engine sqlserver-ex \
  --region us-east-1 \
  --query 'DBEngineVersions[*].EngineVersion'
```

Actualizar la variable `engine_version` en el workspace de Terraform Cloud con una versión disponible.

---

### Problema: No puedo conectarme por RDP a la EC2

**Síntoma:** La conexión RDP (puerto 3389) es rechazada o no hay respuesta.

**Diagnóstico:**
1. Verificar que la instancia EC2 está en estado `running`
2. Verificar la IP pública actual (puede haber cambiado si se reinició)
3. Verificar que tu IP está dentro del CIDR configurado en `allowed_rdp_cidr`
4. Verificar que el Security Group tiene la regla de RDP correcta

```bash
# Verificar Security Group desde AWS CLI
aws ec2 describe-security-groups \
  --group-names "ibm-techxchange-2026-hackaton-sg-ec2" \
  --region us-east-1
```

---

### Problema: La IP pública de la EC2 cambió después de reiniciar

**Síntoma:** La IP pública que tenías ya no funciona.

**Explicación:** La IP pública de la EC2 es dinámica; AWS asigna una nueva IP cada vez que la instancia
se inicia. Esto es comportamiento esperado.

**Solución:**
1. Ver la nueva IP en la consola AWS: **EC2** → **Instances** → columna **Public IPv4 address**
2. O ejecutar desde Terraform Cloud un nuevo plan/apply para actualizar el output `ec2_public_ip`
3. Si necesitas una IP fija, considera asociar una Elastic IP (EIP) — requiere modificar el módulo `ec2-windows`

---

## Rotación de credenciales

### Rotar Access Keys de AWS

1. En la consola AWS, ir a **IAM** → **Users** → seleccionar el usuario
2. Ir a la pestaña **Security credentials**
3. Clic en **Create access key** (nueva clave)
4. **Antes de desactivar la clave vieja**, actualizar en:
   - Terraform Cloud workspace `hackaton`: variables `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`
   - GitHub Actions secrets: `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`
5. Ejecutar un plan de prueba para verificar que la nueva clave funciona
6. Desactivar y luego eliminar la clave vieja en IAM

### Rotar contraseña de la base de datos RDS

1. En Terraform Cloud workspace `hackaton`, actualizar la variable `db_password` con la nueva contraseña
2. Ejecutar un nuevo run desde Terraform Cloud o hacer push a `main`
3. Terraform actualizará la contraseña en RDS automáticamente

### Rotar el par de claves SSH de EC2

1. Generar un nuevo par de claves localmente: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/hackaton_keypair_nuevo`
2. En Terraform Cloud workspace `hackaton`, actualizar la variable `public_key_content` con la nueva clave pública
3. Ejecutar un nuevo run — Terraform creará un nuevo key pair en AWS y actualizará la EC2

---

## Destrucción de la infraestructura

> ⚠️ **ADVERTENCIA:** Esta operación es destructiva e irreversible. Todos los datos en la RDS se perderán.

### Desde Terraform Cloud (recomendado)

1. Ir a [app.terraform.io](https://app.terraform.io/)
2. Navegar a: **GBM-HA-TEST** → **Carlos pruebas** → **hackaton**
3. Ir a **Settings** → **Destruction and Deletion**
4. En la sección **Manually destroy**, clic en **Queue destroy plan**
5. Escribir el nombre del workspace (`hackaton`) para confirmar
6. Clic en **Queue destroy plan**
7. Revisar el plan de destrucción
8. Clic en **Confirm & apply**

### Desde la línea de comandos

```bash
cd construccion/terraform
terraform init
terraform destroy -auto-approve
```

---

## Verificación post-despliegue

Ejecutar estas verificaciones tras cada deploy exitoso:

```bash
# 1. Verificar instancia EC2
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ibm-techxchange-2026" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --region us-east-1

# 2. Verificar instancia RDS
aws rds describe-db-instances \
  --db-instance-identifier ibm-techxchange-2026-hackaton-rds-sqlserver \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --region us-east-1

# 3. Verificar Security Groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=ibm-techxchange-2026" \
  --query 'SecurityGroups[*].[GroupName,GroupId]' \
  --region us-east-1
```

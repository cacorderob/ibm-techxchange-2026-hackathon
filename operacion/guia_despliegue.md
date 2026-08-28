# Guía de Despliegue

## Requisitos previos

Antes de iniciar el despliegue, verifica que tienes:

- [ ] Cuenta AWS activa con los permisos necesarios (EC2, RDS, VPC, IAM)
- [ ] Cuenta en [Terraform Cloud](https://app.terraform.io/) con acceso a la organización `GBM-HA-TEST`
- [ ] Acceso de escritura al repositorio `cacorderob/ibm-techxchange-2026-hackathon`
- [ ] Par de claves SSH generado localmente
- [ ] Credenciales AWS (Access Key ID + Secret Access Key) con permisos de infraestructura

---

## Paso 1 — Generar el par de claves SSH

Si no tienes un par de claves SSH para el key pair de la EC2:

```bash
# Generar un nuevo par de claves RSA de 4096 bits
ssh-keygen -t rsa -b 4096 -C "hackaton-ibm-techxchange-2026" -f ~/.ssh/hackaton_keypair

# El comando generará dos archivos:
#   ~/.ssh/hackaton_keypair     → clave PRIVADA (guardar de forma segura, nunca compartir)
#   ~/.ssh/hackaton_keypair.pub → clave PÚBLICA (esta se configura en Terraform Cloud)

# Ver el contenido de la clave pública para copiarla
cat ~/.ssh/hackaton_keypair.pub
```

Copia el contenido completo de la clave pública — la necesitarás en el Paso 3.

---

## Paso 2 — Configurar el workspace en Terraform Cloud

Sigue la guía completa en [`guia_terraform_cloud.md`](./guia_terraform_cloud.md).

Resumen de lo que debes configurar:
1. Crear el workspace `hackaton` en el proyecto `Carlos pruebas` de la organización `GBM-HA-TEST`
2. Conectar el workspace al VCS Provider del repositorio GitHub
3. Crear todas las variables listadas en la guía

---

## Paso 3 — Configurar secrets en GitHub Actions

En tu repositorio GitHub (`cacorderob/ibm-techxchange-2026-hackathon`):

1. Ir a **Settings** → **Secrets and variables** → **Actions**
2. Crear los siguientes **Repository secrets** (clic en **New repository secret**):

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Tu Access Key ID de AWS |
| `AWS_SECRET_ACCESS_KEY` | Tu Secret Access Key de AWS |
| `TF_API_TOKEN` | Token de Terraform Cloud (ver instrucciones abajo) |

### Cómo obtener el TF_API_TOKEN

1. Ir a [app.terraform.io](https://app.terraform.io/)
2. Hacer clic en tu avatar (esquina superior derecha) → **User Settings**
3. Ir a la sección **Tokens**
4. Clic en **Create an API token**
5. Ingresar una descripción: `GitHub Actions — hackaton`
6. Copiar el token generado (solo se muestra una vez)
7. Pegarlo como valor del secret `TF_API_TOKEN` en GitHub

---

## Paso 4 — Configurar el environment de aprobación en GitHub

El pipeline requiere un environment llamado `produccion` con aprobación manual:

1. En tu repositorio GitHub, ir a **Settings** → **Environments**
2. Clic en **New environment**
3. Nombre: `produccion`
4. En **Environment protection rules**, habilitar **Required reviewers**
5. Agregar tu usuario (`cacorderob`) como reviewer requerido
6. Clic en **Save protection rules**

---

## Paso 5 — Clonar el repositorio localmente (opcional)

Si quieres revisar o modificar el código antes del despliegue:

```bash
# Clonar el repositorio
git clone https://github.com/cacorderob/ibm-techxchange-2026-hackathon.git
cd ibm-techxchange-2026-hackathon

# Verificar la estructura del proyecto
ls -la
```

---

## Paso 6 — Ejecutar el pipeline DevSecOps

### Opción A: Despliegue via push a main (recomendado)

```bash
# Si clonaste el repositorio y realizaste cambios, hacer push a main
git add .
git commit -m "feat(infraestructura): despliega EC2 Windows y RDS SQL Server"
git push origin main
```

El pipeline se dispara automáticamente al hacer push a `main`.

### Opción B: Disparar manualmente desde GitHub Actions

1. Ir al repositorio en GitHub
2. Clic en la pestaña **Actions**
3. Seleccionar el workflow **DevSecOps Pipeline — Infraestructura AWS**
4. Clic en **Run workflow** → seleccionar rama `main` → **Run workflow**

---

## Paso 7 — Monitorear el pipeline

1. Ir a **Actions** en el repositorio GitHub
2. Seleccionar la ejecución más reciente del workflow `DevSecOps Pipeline`
3. Verificar que los jobs de seguridad y validación pasan correctamente
4. Cuando llegue al job **Aprobación Manual Requerida**, recibirás una notificación por email
5. Ir a Actions → seleccionar la ejecución → clic en **Review deployments**
6. Seleccionar `produccion` y clic en **Approve and deploy**

---

## Paso 8 — Verificar el aprovisionamiento en AWS

Tras el apply exitoso, verifica en la consola de AWS:

### Verificar EC2
```
AWS Console → EC2 → Instances → buscar "ibm-techxchange-2026-hackaton-ec2-windows"
```
- Estado: `running`
- IP pública: aparece en la columna **Public IPv4 address**
- Sistema operativo: Windows Server 2022

### Verificar RDS
```
AWS Console → RDS → Databases → buscar "ibm-techxchange-2026-hackaton-rds-sqlserver"
```
- Estado: `available`
- Motor: SQL Server Express 15.00
- Endpoint: disponible en los detalles de la instancia

### Verificar outputs de Terraform
En Terraform Cloud → workspace `hackaton` → **Outputs**, verás:
- `ec2_instance_id`
- `ec2_public_ip` (IP dinámica asignada por AWS)
- `ec2_security_group_name`
- `rds_port`
- `rds_endpoint` (marcado como sensible)

---

## Paso 9 — Conectarse a la instancia EC2 (verificación)

```
1. Obtener la IP pública desde los outputs de Terraform o la consola AWS
2. Abrir Remote Desktop Connection (Windows) o Remmina (Linux)
3. Conectarse a: {IP_PUBLICA}:3389
4. Usar las credenciales del administrador de Windows
   (la contraseña inicial se obtiene desde la consola AWS usando la clave privada)
```

**Nota:** Solo podrás conectarte desde el CIDR que configuraste en `TF_VAR_allowed_rdp_cidr`.

---

## Cómo destruir la infraestructura

### Opción A: Desde Terraform Cloud (recomendado)
1. Ir a [app.terraform.io](https://app.terraform.io/)
2. Organización `GBM-HA-TEST` → Proyecto `Carlos pruebas` → workspace `hackaton`
3. Ir a **Settings** → **Destruction and Deletion**
4. Clic en **Queue destroy plan**
5. Confirmar escribiendo el nombre del workspace
6. Aprobar el plan de destrucción

### Opción B: Desde la línea de comandos
```bash
cd construccion/terraform
terraform init
terraform destroy
# Escribir 'yes' cuando se solicite confirmación
```

# Guía de Configuración — Terraform Cloud

## Datos del workspace

| Dato | Valor |
|------|-------|
| **URL** | [https://app.terraform.io/](https://app.terraform.io/) |
| **Organización** | `GBM-HA-TEST` |
| **Proyecto** | `Carlos pruebas` |
| **Workspace** | `hackaton` |
| **Repositorio VCS** | `cacorderob/ibm-techxchange-2026-hackathon` |
| **Directorio de trabajo** | `construccion/terraform` |
| **Rama VCS** | `main` |

---

## Parte 1 — Conectar el VCS Provider (si no está configurado)

Antes de crear el workspace, asegúrate de que GitHub está configurado como VCS Provider:

1. Ir a [app.terraform.io](https://app.terraform.io/)
2. Seleccionar la organización **GBM-HA-TEST**
3. Ir a **Settings** (engranaje en la barra lateral izquierda)
4. En el menú lateral, seleccionar **Version Control** → **Providers**
5. Clic en **Add a VCS Provider**
6. Seleccionar **GitHub.com**
7. Seguir las instrucciones para autorizar Terraform Cloud en tu cuenta de GitHub
8. Una vez completado, Terraform Cloud aparecerá como aplicación OAuth autorizada en GitHub

---

## Parte 2 — Crear el workspace `hackaton`

### Paso 1: Navegar al proyecto correcto

1. Ir a [app.terraform.io](https://app.terraform.io/)
2. Seleccionar la organización **GBM-HA-TEST**
3. En el panel izquierdo, buscar y seleccionar el proyecto **Carlos pruebas**
4. Clic en **+ New workspace**

### Paso 2: Seleccionar tipo de workflow

1. En la pantalla "Choose your workflow", seleccionar **Version control workflow**
2. Clic en **Next**

### Paso 3: Conectar al repositorio

1. En "Connect to a version control provider", seleccionar **GitHub.com** (el VCS configurado)
2. Buscar y seleccionar el repositorio: `cacorderob/ibm-techxchange-2026-hackathon`
3. Clic en **Next**

### Paso 4: Configurar el workspace

Completar los campos con los siguientes valores:

| Campo | Valor |
|-------|-------|
| **Workspace name** | `hackaton` |
| **Project** | `Carlos pruebas` |
| **Terraform working directory** | `construccion/terraform` |
| **VCS branch** | `main` |
| **Auto apply** | Deshabilitado (usaremos el gate manual de GitHub Actions) |
| **Automatic run triggering** | Habilitado para la rama `main` |

5. Clic en **Create workspace**

---

## Parte 3 — Crear las variables del workspace

Una vez creado el workspace, ir a:
`Workspace hackaton` → **Variables** → **+ Add variable**

Crear las siguientes variables **exactamente** con los nombres indicados:

### Variables de entorno de AWS (Environment Variables)

Estas variables son inyectadas como variables de entorno del sistema operativo durante la ejecución de Terraform.

| Nombre de la variable | Categoría | Sensitive | Descripción |
|-----------------------|-----------|-----------|-------------|
| `AWS_ACCESS_KEY_ID` | Environment variable | ✅ Sí | Access Key ID de la cuenta AWS. Se obtiene desde IAM → Access Keys. |
| `AWS_SECRET_ACCESS_KEY` | Environment variable | ✅ Sí | Secret Access Key de la cuenta AWS. Se obtiene junto al Access Key ID. |

**Cómo crear una variable de entorno:**
1. Clic en **+ Add variable**
2. En **Variable category**, seleccionar **Environment variable**
3. Escribir el nombre exactamente como aparece en la tabla
4. Pegar el valor correspondiente
5. Marcar la casilla **Sensitive** si aplica
6. Clic en **Save variable**

---

### Variables de Terraform (Terraform Variables)

Estas variables corresponden a las variables declaradas en el código Terraform (`variables.tf`).

| Nombre de la variable | Categoría | Sensitive | Tipo HCL | Descripción y ejemplo de valor |
|-----------------------|-----------|-----------|----------|-------------------------------|
| `db_username` | Terraform variable | ✅ Sí | String | Usuario administrador de RDS SQL Server. Ej: `admindbhackaton` |
| `db_password` | Terraform variable | ✅ Sí | String | Contraseña del admin de RDS. Mínimo 8 caracteres. Ej: `MiContr4seña-Segura!` |
| `public_key_content` | Terraform variable | ✅ Sí | String | Contenido completo de la clave pública SSH. Ej: `ssh-rsa AAAAB3Nza... usuario@equipo` |
| `allowed_rdp_cidr` | Terraform variable | ❌ No | String | CIDR desde donde se permite RDP. Ej: `203.0.113.10/32` |
| `environment` | Terraform variable | ❌ No | String | Nombre del ambiente. Valor: `hackaton` |
| `project_name` | Terraform variable | ❌ No | String | Nombre del proyecto. Valor: `ibm-techxchange-2026` |
| `owner` | Terraform variable | ❌ No | String | Propietario. Valor: `cacorderob` |

**Cómo crear una variable de Terraform:**
1. Clic en **+ Add variable**
2. En **Variable category**, seleccionar **Terraform variable**
3. Escribir el nombre exactamente como aparece en la tabla (sin prefijo `TF_VAR_`)
4. Pegar el valor correspondiente
5. Marcar la casilla **Sensitive** si aplica
6. **No** marcar HCL a menos que el valor sea una lista o mapa
7. Clic en **Save variable**

> **Nota sobre `public_key_content`:** El valor debe ser el contenido completo del archivo `.pub`,
> incluyendo el tipo de clave al inicio. Ejemplo:
> `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7... usuario@equipo`

---

## Parte 4 — Verificar la configuración

### Verificar variables
1. Ir al workspace `hackaton` → **Variables**
2. Verificar que aparecen las 9 variables (2 de entorno + 7 de Terraform)
3. Las variables sensibles deben mostrar `••••••••` en lugar del valor

### Verificar conexión VCS
1. Ir al workspace `hackaton` → **Settings** → **Version Control**
2. Verificar que muestra:
   - Repositorio: `cacorderob/ibm-techxchange-2026-hackathon`
   - Rama: `main`
   - Directorio de trabajo: `construccion/terraform`

### Ejecutar un plan de prueba
1. Ir al workspace `hackaton`
2. Clic en **+ New run**
3. Seleccionar **Plan only**
4. Clic en **Start run**
5. Verificar que el plan se ejecuta sin errores de autenticación ni variables faltantes

---

## Parte 5 — Configurar notificaciones (opcional)

Para recibir notificaciones por email cuando el apply complete:

1. Ir al workspace `hackaton` → **Settings** → **Notifications**
2. Clic en **Create a notification**
3. Seleccionar **Email**
4. Agregar los emails de los destinatarios
5. Seleccionar los eventos: **Run completed**, **Run errored**, **Assessment failed**
6. Clic en **Create notification**

---

## Resumen de variables — Referencia rápida

```
VARIABLES DE ENTORNO (Environment Variables):
┌──────────────────────────────┬───────────────┬──────────┐
│ Nombre                       │ Categoría     │ Sensible │
├──────────────────────────────┼───────────────┼──────────┤
│ AWS_ACCESS_KEY_ID            │ Environment   │   SI     │
│ AWS_SECRET_ACCESS_KEY        │ Environment   │   SI     │
└──────────────────────────────┴───────────────┴──────────┘

VARIABLES DE TERRAFORM (Terraform Variables):
┌──────────────────────────────┬───────────────┬──────────┐
│ Nombre                       │ Categoría     │ Sensible │
├──────────────────────────────┼───────────────┼──────────┤
│ db_username                  │ Terraform     │   SI     │
│ db_password                  │ Terraform     │   SI     │
│ public_key_content           │ Terraform     │   SI     │
│ allowed_rdp_cidr             │ Terraform     │   NO     │
│ environment                  │ Terraform     │   NO     │
│ project_name                 │ Terraform     │   NO     │
│ owner                        │ Terraform     │   NO     │
└──────────────────────────────┴───────────────┴──────────┘
```

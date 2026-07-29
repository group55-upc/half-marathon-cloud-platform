# Half Marathon Cloud Platform

Plataforma web cloud-native para consultar medias maratones, desplegada en AWS con
infraestructura como código.

## Objetivo

Construir una aplicación web que permita buscar medias maratones por ciudad, país o
distancia, consultar la información de cada carrera y registrar carreras nuevas.

## Estado actual

La plataforma está **desplegada y funcional** de extremo a extremo: frontend en S3,
API en contenedores sobre ECS Fargate detrás de un balanceador, y datos en DynamoDB.

Del objetivo original quedan dos funcionalidades pendientes, detalladas en
[Limitaciones conocidas](#limitaciones-conocidas): la búsqueda por fecha y la
visualización del circuito de cada carrera.

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Angular 22 (componentes standalone, signals) |
| Hosting del frontend | Amazon S3 como sitio web estático |
| API | Node.js 24 + Express 5 |
| Contenedores | Docker, imagen basada en `node:24.16-alpine` |
| Registro de imágenes | Amazon ECR |
| Orquestación | Amazon ECS con Fargate |
| Balanceo | Application Load Balancer |
| Base de datos | Amazon DynamoDB (NoSQL) |
| Infraestructura como código | Terraform |
| Logs | Amazon CloudWatch Logs |

## Arquitectura

```
                        Internet
                           |
        +------------------+------------------+
        |                                     |
        v                                     v
  S3 (sitio estático)              ALB (puerto 80, público)
  Frontend Angular                          |
                                            v
                              ECS Fargate (subred privada)
                              2 tareas, backend Node.js:5000
                                            |
                                    VPC Endpoint (Gateway)
                                            |
                                            v
                                  DynamoDB (tabla races)
```

El navegador del usuario hace dos tipos de petición: descarga la web desde S3, y desde
ahí llama a la API a través del balanceador. El backend nunca es accesible
directamente: vive en una subred privada sin IP pública y solo acepta tráfico
procedente del balanceador.

La descripción detallada de cada componente, el diseño de red y los flujos de datos
están en [`docs/architecture.md`](docs/architecture.md).

## Estructura del repositorio

### Entrega del proyecto

| Carpeta | Contenido |
|---|---|
| `backend/code/` | API Node.js + Express y su `Dockerfile` |
| `backend/infra/` | **Infraestructura real desplegada** (Terraform) |
| `frontend/code/` | Aplicación Angular |
| `database/` | Modelo de datos y carga de datos de ejemplo |
| `docs/` | Documentación de arquitectura, planificación y mejoras propuestas |
| `deploy.ps1` | Despliegue completo automatizado (Windows) |
| `.github/workflows/` | Pipelines de integración continua y de despliegue |

### Desarrollos paralelos e histórico

Estas carpetas no forman parte de la entrega, pero se conservan por su valor
documental:

| Carpeta | Contenido |
|---|---|
| `Miquel/` | Implementación individual completa y alternativa: backend, frontend e infraestructura propia sobre EC2. Independiente del despliegue oficial. |
| `oscar/` | Exploración inicial de la infraestructura en Terraform, previa a `backend/infra/`. |
| `infrastructure/terraform/` | Esqueleto del planteamiento inicial. **No se usa.** |
| `kubernetes/` | Manifests del planteamiento inicial con EKS. **No se usa.** |
| `lambdas/` | Función de importación prevista como opcional. **No implementada.** |

## Despliegue

> **Antes de nada: solo una persona del equipo puede tener la infraestructura
> desplegada a la vez.** El nombre del bucket de S3 está fijado en el código, y los
> nombres de bucket son únicos a escala mundial en AWS, no por cuenta. Si otro
> integrante ya tiene el despliegue levantado, el `terraform apply` fallará con
> `BucketAlreadyExists`. Coordinadlo antes de empezar.

### Requisitos previos

**1. Herramientas.** Las cuatro deben estar instaladas y accesibles desde el PATH:

| Herramienta | Versión | Comando de verificación |
|---|---|---|
| AWS CLI | v2 | `aws --version` |
| Terraform | 1.x | `terraform version` |
| Docker Desktop | reciente | `docker --version` |
| Node.js + npm | 24.x | `node -v` y `npm -v` |

Si acabas de instalar alguna, **cierra y vuelve a abrir la terminal**: el PATH no se
actualiza en las ventanas ya abiertas.

**2. Docker Desktop arrancado.** No basta con tenerlo instalado. Ábrelo y espera a que
la barra inferior indique *Engine running*. Verificación:

```powershell
docker info
```

Si devuelve información del sistema, está listo. Los avisos sobre `blkio` o WSL2 son
normales e inofensivos.

**3. Laboratorio de AWS Academy arrancado.** Entra en el laboratorio y pulsa **Start
Lab**. Espera a que el indicador se ponga **verde**.

**4. Credenciales configuradas.** En el laboratorio, pulsa **AWS Details** →
**AWS CLI: Show** y copia el bloque completo. Pégalo en el archivo de credenciales,
sustituyendo su contenido anterior:

```powershell
# Crear el archivo la primera vez
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.aws" | Out-Null
New-Item -ItemType File -Force -Path "$env:USERPROFILE\.aws\credentials" | Out-Null

# Abrirlo para pegar las credenciales
notepad "$env:USERPROFILE\.aws\credentials"
```

El contenido debe quedar así, incluida la línea `[default]`:

```ini
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

Y la configuración de región, solo la primera vez:

```powershell
Set-Content "$env:USERPROFILE\.aws\config" "[default]`nregion = us-east-1`noutput = json"
```

> Las credenciales del laboratorio **caducan cada pocas horas** y con cada reinicio de
> la sesión. Cuando veas errores de autorización simultáneos en todos los servicios,
> la causa es siempre esta: reinicia el laboratorio y repite este paso.

**5. Comprobación final.** Este comando debe devolver tu cuenta y tu ARN:

```powershell
aws sts get-caller-identity
```

Si falla con `AccessDenied`, `ExpiredToken` o una mención a `voc-cancel-cred`, el
laboratorio no está arrancado o las credenciales están caducadas.

**6. Región.** El despliegue funciona únicamente en `us-east-1`. La región está fijada
en `backend/code/db.js`, en `backend/infra/variables.tf`, en los nombres de servicio de
los VPC endpoints y en el propio script.

### Automatizado (Windows)

```powershell
cd <raíz del repositorio>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy.ps1
```

`Set-ExecutionPolicy` con `-Scope Process` levanta el bloqueo de scripts **solo en esa
ventana de PowerShell**; al cerrarla vuelve al estado original. No modifica nada
permanente en el sistema.

El script ejecuta las ocho fases del despliegue en orden, verifica el resultado de cada
una antes de continuar y espera a que el backend responda antes de publicar el
frontend. Al final imprime las URLs.

| | Primer despliegue | Redespliegue |
|---|---|---|
| Duración | 10–15 min | ~2 min |

La fase más lenta es la creación del Application Load Balancer, unos 3 minutos. La fase
6 (*Esperando a que el backend esté disponible*) imprime `esperando... intento N de 40`
y puede parecer bloqueada: es el arranque normal de las tareas Fargate, entre 1 y 3
minutos.

**No cierres la ventana durante el despliegue.**

Opciones: `-SkipFrontend` para desplegar solo la infraestructura y el backend,
`-SkipSeed` para no cargar datos de ejemplo.

### Verificación posterior

```powershell
# La API responde
Invoke-RestMethod "http://<url-del-alb>/"            # → status ok

# La API alcanza la base de datos
Invoke-RestMethod "http://<url-del-alb>/connection"  # → status ok

# Hay datos
Invoke-RestMethod "http://<url-del-alb>/races"       # → 12 carreras
```

Y abre la web en el navegador. **Con `http://`, nunca `https://`** (ver la tabla de
errores). Debe mostrar las carreras y el indicador *Service Online* en verde.

En PowerShell usa `Invoke-RestMethod`, no `curl`: en PowerShell `curl` es un alias de
`Invoke-WebRequest` y muestra un aviso de seguridad. Si necesitas el `curl` auténtico,
invócalo como `curl.exe`.

### Errores frecuentes

| Error | Causa | Solución |
|---|---|---|
| `AccessDenied` o `voc-cancel-cred` en todos los servicios | La sesión del laboratorio está detenida | **Start Lab** y renovar las credenciales |
| `ExpiredToken` | Credenciales caducadas | Renovar las credenciales |
| `no se puede cargar porque la ejecución de scripts está deshabilitada` | Política de ejecución de PowerShell | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| `No encuentro 'terraform'` (o docker, aws, npm) | No instalado, o terminal abierta antes de instalarlo | Instalar y **abrir una terminal nueva** |
| `Docker esta instalado pero no responde` | Docker Desktop cerrado | Arrancarlo y esperar a *Engine running* |
| `BucketAlreadyExists` | Otro integrante tiene la infraestructura desplegada | Esperar a que la destruya, o dar nombres de bucket distintos |
| `CannotPullContainerError` en las tareas ECS | El servicio se creó antes de existir la imagen en ECR | El script lo evita. Si ocurre manualmente: subir la imagen y forzar un nuevo despliegue del servicio |
| `400 Bad Request` en el login contra ECR | PowerShell añade `\r\n` al canalizar el token | Resuelto en el script. Manualmente, ejecutar el login desde `cmd.exe` |
| `ERR_CONNECTION_RESET` al abrir la web | El navegador fuerza HTTPS, y el sitio web de S3 solo admite HTTP | Escribir `http://` explícitamente. Si persiste, desactivar *Usar siempre conexiones seguras* en la configuración del navegador, o usar otro navegador |
| La web carga pero sin datos | La URL del balanceador del frontend no corresponde al despliegue actual | Volver a ejecutar `deploy.ps1`, que la inyecta automáticamente |
| `terraform destroy` falla con errores de autorización | El laboratorio está detenido | Arrancar el laboratorio antes de destruir |

### Manual (cualquier sistema)

El procedimiento paso a paso, incluido el modo de pruebas en local, está en
[`backend/README.md`](backend/README.md).

Es importante respetar el orden: **la imagen del contenedor debe existir en ECR antes
de crear el servicio ECS.** Por eso el despliegue se hace en dos fases, controladas
con la variable `enable-ECS` de `backend/infra/backend.auto.tfvars`. Si se crea el
servicio antes de subir la imagen, las tareas fallan con `CannotPullContainerError`.

### Cargar datos de ejemplo

```powershell
.\database\seed-races.ps1 -ApiUrl "http://<url-del-alb>"
```

### Destruir la infraestructura

```powershell
cd backend/infra
terraform destroy
```

> **Importante para el coste.** Cerrar la sesión del laboratorio **no detiene** el
> balanceador, las tareas Fargate ni los VPC endpoints: siguen consumiendo crédito.
> La infraestructura cuesta aproximadamente **3,12 USD al día** estando inactiva
> (~1,20 de Fargate, ~1,44 de los VPC endpoints de tipo Interface, ~0,54 del ALB).
> Conviene destruirla al terminar cada sesión de trabajo.
>
> Los endpoints de tipo Interface **se facturan por zona de disponibilidad**. Al
> desplegar el backend en dos zonas para obtener alta disponibilidad real, los tres
> endpoints pasan a crear seis interfaces de red en lugar de tres. La tolerancia al
> fallo de una zona cuesta por tanto 0,72 USD diarios adicionales.
>
> Cada integrante tiene su propio `terraform.tfstate` local, así que cada despliegue
> crea una infraestructura completamente independiente. Tres despliegues simultáneos
> triplican el coste.

## Integración continua y despliegue

El repositorio incluye dos pipelines en `.github/workflows/`.

### `ci.yml` — automático

Se ejecuta en cada `push` a `main` y en cada *pull request*. **No requiere
credenciales de AWS**, por lo que funciona siempre. Tres trabajos en paralelo:

| Trabajo | Comprueba |
|---|---|
| `terraform` | Formato (informativo) y validez de la configuración de infraestructura |
| `frontend` | Que las dependencias instalan y que la aplicación compila |
| `backend` | Sintaxis, auditoría de dependencias, construcción de la imagen y análisis de vulnerabilidades con Trivy |

El trabajo `frontend` incluye una **guarda de regresión**: cuenta los archivos `.ts`
en el resultado de la compilación y falla si encuentra alguno. Impide que reaparezca
el defecto por el que el código fuente acabó publicado en el bucket público.

### `deploy.yml` — manual

Se lanza desde la pestaña **Actions** del repositorio. Despliega **la aplicación**
sobre una infraestructura ya existente: publica la imagen en ECR, fuerza el
redespliegue del servicio ECS, espera a que la API responda, compila el frontend
inyectando la dirección del balanceador y lo publica en S3.

Etiqueta la imagen dos veces: como `v1.0`, que es la referencia fija de la definición
de tarea, y con el hash abreviado del commit, lo que aporta trazabilidad de versiones.

**Por qué es manual y no continuo.** Dos razones técnicas:

1. Las credenciales del laboratorio caducan cada pocas horas. Un despliegue en cada
   cambio fallaría la mayor parte del tiempo.
2. El estado de Terraform se mantiene en local. El pipeline no puede por tanto crear
   ni modificar la infraestructura, únicamente desplegar la aplicación sobre una
   infraestructura previamente creada con `deploy.ps1`.

**Requisitos.** Configurar en Settings → Secrets and variables → Actions los secretos
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_SESSION_TOKEN`, que hay que
actualizar cada vez que se reinicie el laboratorio.

## API

Base: `http://<url-del-alb>`

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/` | Health check. Devuelve `{"status":"ok"}` |
| `GET` | `/connection` | Comprueba la conectividad con DynamoDB |
| `GET` | `/races` | Devuelve todas las carreras |
| `GET` | `/races?id=<id>` | Devuelve una carrera por su identificador |
| `GET` | `/races?city=Madrid&country=Spain` | Filtra por coincidencia exacta de campos |
| `POST` | `/races` | Crea una carrera |

Cuerpo del `POST`:

```json
{
  "name": "Mitja Marató de Barcelona",
  "city": "Barcelona",
  "country": "Spain",
  "date": "2027-02-14",
  "web": "https://ejemplo.com",
  "distance": 21.0975
}
```

El identificador lo genera el backend combinando la marca de tiempo con un número
aleatorio. No existen operaciones de modificación ni de borrado.

## Decisiones de diseño y desviaciones respecto al plan inicial

El planteamiento original del proyecto contemplaba React, PostgreSQL en RDS y EKS.
La implementación final difiere en tres puntos. Se documentan aquí por transparencia:

| Previsto | Implementado | Motivo |
|---|---|---|
| React + Vite | Angular 22 | _(a completar por el equipo)_ |
| PostgreSQL en Amazon RDS | DynamoDB | Decisión deliberada de trabajar con servicios de AWS no cubiertos en clase, para ampliar el alcance formativo del proyecto |
| EKS + Kubernetes | ECS Fargate | Ídem. Fargate elimina además la gestión de nodos, lo que reduce la complejidad operativa frente a EKS |

El equipo optó conscientemente por explorar servicios de AWS que no se habían visto en
las sesiones teóricas (DynamoDB como base de datos NoSQL, ECS Fargate como cómputo sin
servidores que administrar) en lugar de limitarse a los prescritos en el planteamiento
inicial. El archivo `amplify.yml` de la raíz responde a la misma intención, aunque
Amplify no se llegó a utilizar en el despliegue final.

Los archivos `database/schema.sql` y `database/seed.sql` corresponden al modelo
relacional del diseño inicial y se conservan como documentación de esa fase. No son
ejecutables sobre DynamoDB, que no utiliza SQL.

> Nota para el equipo: rellenar la columna de motivos es importante para la
> evaluación. Una desviación justificada respecto al diseño inicial demuestra
> criterio; una desviación sin explicar parece improvisación.

## Limitaciones conocidas

**Funcionales**

- No existe búsqueda por fecha, prevista en el objetivo del proyecto.
- No existe visualización del circuito de cada carrera. El backend tampoco acepta
  subida de archivos.
- No se pueden modificar ni eliminar carreras: la API solo implementa `GET` y `POST`.
- El frontend descarga el catálogo completo y filtra en el navegador. Es adecuado para
  el volumen actual, pero no escala. La solución serían índices secundarios en
  DynamoDB más paginación.

**De infraestructura**

- **Todo el tráfico va por HTTP sin cifrar.** Los endpoints de sitio web estático de
  S3 no soportan HTTPS, y el balanceador solo tiene un listener en el puerto 80.
  Resolverlo requiere CloudFront delante del bucket y un certificado de ACM en el
  balanceador, y la validación del certificado necesita un dominio propio, algo no
  disponible en el laboratorio.
- El nombre del bucket de S3 es fijo, y los nombres de bucket son únicos globalmente
  en AWS. Solo un integrante puede tener la infraestructura levantada a la vez.
- La URL del balanceador está escrita en el código del frontend y cambia con cada
  despliegue.
- La imagen del contenedor se etiqueta siempre como `v1.0`, sobrescribiendo la
  anterior. No hay historial de versiones ni posibilidad de volver atrás.
- El despliegue depende del rol `LabRole`, que solo existe en los laboratorios de AWS
  Academy. El proyecto no es portable a una cuenta de AWS convencional sin cambios.

- **No se ha podido integrar Amazon Bedrock**, previsto como funcionalidad opcional
  en el planteamiento inicial. El rol de usuario del laboratorio carece del permiso
  `bedrock:ListFoundationModels`, y no es posible auditar los permisos del rol de
  ejecución de las tareas porque el acceso a IAM está denegado explícitamente.
  Además, dado que las tareas no tienen salida a internet y Bedrock no dispone de
  endpoint de tipo Gateway, la integración exigiría un endpoint adicional de tipo
  Interface con un coste de 0,48 USD diarios.

**De calidad**

- No hay pruebas automatizadas.
- El despliegue automatizado desde el pipeline es de disparo manual, no continuo.
  Las razones son dos: las credenciales del laboratorio caducan cada pocas horas,
  y el estado de Terraform es local, por lo que el pipeline no puede gestionar la
  infraestructura, únicamente desplegar la aplicación sobre ella.

El análisis completo, con la solución concreta y el esfuerzo estimado de cada punto,
está en [`docs/mejoras-propuestas.md`](docs/mejoras-propuestas.md).

## Equipo

Grupo 5 — Universitat Politècnica de Catalunya.

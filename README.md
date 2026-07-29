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
| `.github/workflows/` | Pipeline de CI vacío (solo un `echo` de marcador). |

## Despliegue

### Requisitos

- AWS CLI v2, Terraform 1.x, Docker Desktop (arrancado), Node.js 24
- Credenciales válidas de AWS Academy con el laboratorio **arrancado**
- Región `us-east-1` (está fijada en el código y en la configuración)

### Automatizado (Windows)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy.ps1
```

Ejecuta las ocho fases del despliegue en orden, comprueba cada una antes de continuar
y espera a que el backend responda antes de publicar el frontend. Tarda entre 10 y 15
minutos. Al final imprime las URLs.

Opciones: `-SkipFrontend` para desplegar solo la infraestructura y el backend,
`-SkipSeed` para no cargar datos de ejemplo.

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
> La infraestructura cuesta aproximadamente **2,40 USD al día** estando inactiva
> (~1,20 de Fargate, ~0,72 de los tres VPC endpoints de tipo Interface, ~0,54 del ALB).
> Conviene destruirla al terminar cada sesión de trabajo.
>
> Cada integrante tiene su propio `terraform.tfstate` local, así que cada despliegue
> crea una infraestructura completamente independiente. Tres despliegues simultáneos
> triplican el coste.

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
- El backend corre en una única zona de disponibilidad. El balanceador está en dos,
  pero la subred privada solo existe en `us-east-1a`.
- El nombre del bucket de S3 es fijo, y los nombres de bucket son únicos globalmente
  en AWS. Solo un integrante puede tener la infraestructura levantada a la vez.
- La URL del balanceador está escrita en el código del frontend y cambia con cada
  despliegue.
- La imagen del contenedor se etiqueta siempre como `v1.0`, sobrescribiendo la
  anterior. No hay historial de versiones ni posibilidad de volver atrás.
- El despliegue depende del rol `LabRole`, que solo existe en los laboratorios de AWS
  Academy. El proyecto no es portable a una cuenta de AWS convencional sin cambios.

**De calidad**

- No hay pruebas automatizadas.
- El pipeline de CI está sin implementar.

El análisis completo, con la solución concreta y el esfuerzo estimado de cada punto,
está en [`docs/mejoras-propuestas.md`](docs/mejoras-propuestas.md).

## Equipo

Grupo 5 — Universitat Politècnica de Catalunya.

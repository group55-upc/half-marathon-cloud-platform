# Mejoras propuestas

Revisión del estado del repositorio y del despliegue a 28/07/2026, tras conseguir el
primer despliegue completo end-to-end (frontend en S3 → ALB → ECS Fargate → DynamoDB).

Nada de lo que sigue impide que la plataforma funcione: **funciona**. Son puntos que
conviene decidir en equipo, unos porque son riesgos reales y otros porque afectan a
cómo se evalúa el trabajo.

Cada punto lleva prioridad, el problema, la solución concreta y el esfuerzo estimado.

---

## Prioridad alta

### 1. La documentación describe una arquitectura que no existe

**Problema.** El `README.md` de la raíz y el `docs/architecture.md` describen:

| Documentado | Implementado realmente |
|---|---|
| React + Vite | Angular 22 |
| PostgreSQL en RDS | DynamoDB (tabla `races`) |
| EKS + Kubernetes | ECS Fargate |
| Route 53 + CloudFront | Nada de esto |
| S3 para almacenamiento | S3 como hosting web estático |

No coincide ni una pieza. La carpeta `kubernetes/` y el `infrastructure/terraform/`
de la raíz tampoco corresponden a lo desplegado (lo real está en `backend/infra/`).

**Por qué importa.** Es lo que más peso tiene en la evaluación: quien lea el repo se
encuentra un proyecto que dice ser una cosa y es otra. También desorienta a cualquiera
que se incorpore.

**Solución.** Reescribir los dos documentos con la arquitectura real. Si el cambio de
RDS a DynamoDB y de EKS a ECS fue una decisión consciente (por coste, por simplicidad,
por límites del laboratorio de AWS Academy), **documentarla como tal**: una desviación
justificada respecto al diseño inicial cuenta a favor, una documentación que no cuadra
cuenta en contra.

**Esfuerzo.** 2-3 horas. Es la tarea de mayor retorno de toda la lista.

---

### 2. La URL del backend está escrita dentro del código fuente

**Problema.** En `frontend/code/src/app/services/race.service.ts`:

```ts
private readonly apiUrl = 'http://lb-backend-1129452724.us-east-1.elb.amazonaws.com';
```

El nombre DNS del ALB lo asigna AWS y **cambia en cada `terraform destroy` + `apply`**.
Cada vez que eso pasa hay que editar el `.ts`, recompilar con `ng build` y volver a
subir todo a S3. Y como el valor está comiteado, quien tenga otro despliegue activo se
encuentra el frontend apuntando a una dirección muerta.

Ya ha pasado dos veces: el valor anterior (`lb-backend-1510711001`) era de un
despliegue que ya no existía.

**Solución.** Que la URL se lea en tiempo de ejecución, no que se compile dentro.
Un archivo `config.json` que el frontend carga al arrancar:

`frontend/code/src/config.json`

```json
{ "apiUrl": "http://REEMPLAZAR-POR-EL-ALB" }
```

En `main.ts`, cargarlo antes de arrancar la aplicación y exponerlo mediante un
`InjectionToken` o un servicio de configuración; `race.service.ts` lo consume en lugar
de tener la constante.

La ventaja es que tras cada despliegue basta con regenerar ese único archivo, sin
recompilar:

```powershell
cd backend\infra
$alb = terraform output -raw alb-url
"{ ""apiUrl"": ""http://$alb"" }" | Set-Content ..\..\frontend\code\src\config.json
```

Y `config.json` va al `.gitignore`, con un `config.example.json` comiteado como
plantilla — el mismo patrón que ya usa Miquel con su `.env.example`.

**Esfuerzo.** 1-2 horas.

---

### 3. El código fuente del frontend se está publicando en el bucket público

**Problema.** En `frontend/code/angular.json`:

```json
"assets": [
  { "glob": "**/*", "input": "src" }
]
```

Eso copia **todo** el contenido de `src/` a la carpeta de salida del build. Resultado:
los `.ts`, los `.html` y los `.css` sin compilar acabaron en `dist/Frontend/browser`
y de ahí subieron a S3. Ahora mismo son accesibles públicamente, por ejemplo en
`/app/services/race.service.ts`.

No hay credenciales dentro, así que no es una brecha de seguridad grave, pero es una
configuración incorrecta y en una auditoría se marcaría.

**Solución.** Copiar solo lo que hace falta de verdad, que son las imágenes:

```json
"assets": [
  { "glob": "**/*", "input": "src/images", "output": "images" }
]
```

Después, `npm run build` y `aws s3 sync ... --delete` (el `--delete` es el que limpia
del bucket los archivos que ya no deberían estar).

**Esfuerzo.** 10 minutos.

---

## Prioridad media

### 4. El backend vive en una sola zona de disponibilidad

**Problema.** En `backend/infra/main.tf` hay dos subredes públicas (una por AZ) pero
**una sola subred privada**, fijada a la primera zona:

```hcl
resource "aws_subnet" "private" {
  availability_zone = var.aws-availability-zones[0]
  ...
}
```

El servicio ECS corre 2 réplicas, pero ambas en la misma zona. Si AWS pierde esa zona,
se cae el backend completo. El ALB sí está repartido en dos, así que la mitad de la
infraestructura es redundante y la otra mitad no.

**Solución.** Convertir la subred privada en dos, igual que las públicas:

```hcl
resource "aws_subnet" "private" {
  count             = length(var.aws-availability-zones)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws-availability-zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 2)
  tags              = local.tags
}
```

Y actualizar las referencias a `aws_subnet.private.id` en: la asociación de tabla de
rutas, los tres VPC endpoints de tipo Interface (`ecr.api`, `ecr.dkr`, `logs`) y el
`network_configuration` del servicio ECS, que pasan a recibir la lista completa.

**Esfuerzo.** 30-45 minutos más el `terraform apply`.

---

### 5. El despliegue necesita dos pasadas manuales

**Problema.** El procedimiento actual obliga a: aplicar con `enable-ECS = false`,
construir y subir la imagen a ECR, cambiar la variable a `true` y volver a aplicar.
Si alguien lo hace del tirón, el servicio ECS intenta arrancar antes de que exista la
imagen y falla con `CannotPullContainerError`.

Está bien documentado en `backend/README.md`, pero es un pie forzado y una fuente de
errores para quien despliega por primera vez.

**Solución.** Tres opciones, de menos a más limpia:

1. **Dejarlo como está** y reforzar el aviso en el README. Coste cero.
2. Añadir un `null_resource` con `local-exec` que ejecute el `docker build` y el
   `docker push`, con el servicio ECS dependiendo de él. Automatiza el ciclo completo
   pero mete Docker como dependencia de Terraform, lo cual no es elegante.
3. **Separar en dos estados de Terraform**: `infra-base` (red, DynamoDB, ECR, S3) y
   `infra-app` (ECS, ALB). Es la práctica habitual en producción y elimina la variable
   `enable-ECS`.

Para el alcance de la asignatura, la 1 es defendible si se justifica en la memoria;
la 3 es la que demuestra criterio.

**Esfuerzo.** Opción 1: 15 min. Opción 3: media jornada.

---

### 6. Los filtros del backend no se usan, y además tienen un bug

**Problema.** Son dos cosas entrelazadas.

El dashboard llama a `getRaces()` **sin parámetros**, se descarga todas las carreras y
filtra en el navegador (`dashboard.component.ts`, el `computed()` de `filteredRaces`).
Con 13 carreras es irrelevante; con 10.000 la web se arrastra y se paga tráfico de
salida por nada.

Y el filtrado por parámetros que sí implementa el backend está roto. En
`backend/code/server.js`:

```js
paramValues[`:${key}`] = value; isNaN(value) ? value : Number(value);
```

La segunda sentencia calcula la conversión a número y **no la asigna a nada**. El
resultado se descarta. Así que `?distance=21.0975` viaja a DynamoDB como el texto
`"21.0975"`, que nunca coincide con el número almacenado.

El bug está latente precisamente porque el frontend no usa esa ruta.

**Solución.** Decidir primero el diseño, y luego arreglar en consecuencia.

Si se opta por filtrar en el servidor (lo correcto si el catálogo va a crecer), el
arreglo del backend es una línea:

```js
paramValues[`:${key}`] = isNaN(value) ? value : Number(value);
```

Y luego reconstruir la imagen, subirla a ECR con un tag nuevo y forzar el redespliegue
del servicio ECS.

Si se opta por mantener el filtrado en cliente, documentarlo como decisión consciente
con su justificación, y aun así arreglar la línea para no dejar un endpoint público
que devuelve resultados incorrectos.

Conviene saber también que el filtrado del backend usa `Scan` con `FilterExpression`,
que en DynamoDB **lee la tabla entera y descarta después**: no ahorra lectura, solo
tráfico. Filtrar de verdad en el servidor requeriría índices secundarios (GSI) por
ciudad o por país. Merece un párrafo en la memoria.

**Esfuerzo.** El arreglo, 1 minuto más el redespliegue. La decisión de diseño, una
conversación.

---

### 7. La caché del compilador de Angular está versionada

**Problema.** `frontend/code/.angular/cache/` está comiteada en el repositorio. Son
archivos temporales que Angular regenera solos. Al compilar con una versión distinta
(22.0.4 → 22.0.8), git ve **27 archivos borrados y 52.000 líneas eliminadas** que no
tienen nada que ver con ningún cambio real. Ensucia todos los `git status` y hace que
cualquier revisión de cambios sea ilegible.

**Solución.**

```bash
git rm -r --cached frontend/code/.angular
echo ".angular/" >> .gitignore
git commit -m "chore: dejar de versionar la cache de Angular"
```

**Requiere coordinación**: avisar al equipo de que hagan `pull` justo después, porque
toca muchos archivos.

**Esfuerzo.** 10 minutos.

---

### 8. El repositorio tiene tres implementaciones paralelas

**Problema.** Conviven `backend/` + `frontend/` (la versión oficial), `Miquel/`
(implementación individual completa con su propio backend, frontend e infraestructura
en EC2) y `oscar/` (otra carpeta de Terraform). No está claro para quien llega qué es
la entrega y qué es trabajo exploratorio.

**Solución.** No hace falta borrar nada — el trabajo individual tiene valor. Pero sí
un párrafo en el `README.md` que diga explícitamente qué carpeta constituye la entrega
y qué son desarrollos paralelos, y por qué existen.

**Esfuerzo.** 20 minutos.

---

## Prioridad baja

### 9. El CI/CD es un esqueleto vacío

`.github/workflows/backend-ci.yml` ejecuta literalmente:

```yaml
- name: Placeholder
  run: echo "Backend CI will be configured later"
```

Decidir entre implementarlo de verdad (build de la imagen, `npm audit`, escaneo con
Trivy como sugiere el enunciado) o retirarlo. Un pipeline que no hace nada da peor
impresión que no tener pipeline, porque parece algo empezado y abandonado.

**Esfuerzo.** Retirarlo: 2 minutos. Implementarlo: media jornada.

---

### 10. Dependencias sin usar en el backend

`backend/code/package.json` declara `aws-sdk` (la v2 completa, cuando el código usa la
v3 modular), `pg` (PostgreSQL, que ya no se usa), `jsonwebtoken` (previsto pero no
implementado) y, curiosamente, `npm` e `install` como dependencias del proyecto.

Engordan la imagen Docker y aumentan la superficie de CVEs sin aportar nada.

```bash
cd backend/code
npm uninstall aws-sdk pg jsonwebtoken npm install
```

(Mantener `dotenv`: lo usa el modo de pruebas en local.)

Después reconstruir la imagen y comparar el tamaño — el antes y el después es un dato
bonito para la memoria.

**Esfuerzo.** 15 minutos más el redespliegue.

---

### 11. Los scripts SQL ya no corresponden a la base de datos

`database/schema.sql` y `database/seed.sql` son SQL para PostgreSQL. DynamoDB no
entiende SQL, así que son inservibles tal cual.

En lugar de borrarlos, la opción que aporta más es **conservarlos como el diseño
lógico inicial** y añadir un `database/README.md` que explique la evolución: modelo
relacional pensado al principio, motivos del cambio a NoSQL, y cómo quedó el modelo
final (tabla `races` con clave de partición `id` de tipo string). Eso demuestra
recorrido de diseño en lugar de improvisación.

El `database/seed-races.ps1` recién añadido es el equivalente funcional del `seed.sql`
para la implementación real.

**Esfuerzo.** 30 minutos.

---

## Limitaciones conocidas: documentar, no arreglar

### 12. Toda la plataforma va por HTTP sin cifrar

El frontend se sirve desde el endpoint de web estática de S3, que **solo soporta
HTTP** por diseño de AWS. El ALB tiene únicamente un listener en el puerto 80.

Y las dos mitades están acopladas: si se pusiera el frontend por HTTPS sin hacer lo
mismo con el ALB, el navegador bloquearía todas las llamadas a la API por *mixed
content* — una página segura no puede invocar un endpoint inseguro.

La solución completa serían las dos piezas a la vez: CloudFront delante del bucket
(que aporta HTTPS gratis) y un listener 443 en el ALB con un certificado de ACM. En un
laboratorio de AWS Academy el certificado es la parte complicada, porque validarlo
requiere un dominio propio.

**Recomendación.** No intentar arreglarlo. Documentarlo como limitación consciente del
entorno de prácticas, con la arquitectura objetivo descrita como línea de trabajo
futura. Reconocer una limitación y saber explicar cómo se resolvería en producción vale
más que dejarla sin mencionar.

---

## Orden sugerido

Si hay que priorizar con tiempo limitado:

1. **Punto 1** (documentación) — el de mayor impacto en la evaluación.
2. **Punto 3** (código fuente expuesto) — 10 minutos y elimina un fallo objetivo.
3. **Punto 2** (URL en configuración) — deja de doler en cada despliegue.
4. **Punto 12** (documentar el HTTP) — se resuelve escribiendo, no tocando código.
5. **Punto 7** (caché de Angular) — hace legible cualquier revisión futura.
6. El resto, según tiempo disponible.

Los puntos 1, 4, 8, 11 y 12 se resuelven escribiendo documentación, y son justo los
que más pesan en la nota. Los puntos 3, 6, 7 y 10 son arreglos de minutos.

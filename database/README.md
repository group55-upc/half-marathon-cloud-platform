# Database

Modelo de datos del proyecto y su evolución.

## Owner

Miquel. Documentación de la implementación final: Itzel.

---

## Estado actual: DynamoDB

La implementación desplegada utiliza **Amazon DynamoDB**, una base de datos
NoSQL. Una sola tabla.

### Tabla `races`

| Parámetro | Valor |
|---|---|
| Clave de partición | `id`, tipo cadena |
| Clave de ordenación | No tiene |
| Índices secundarios | Ninguno |
| Facturación | `PAY_PER_REQUEST` (bajo demanda) |

### Estructura de los elementos

| Atributo | Tipo | Descripción |
|---|---|---|
| `id` | Cadena | Clave de partición. La genera la API como `<marca de tiempo>-<aleatorio>` |
| `name` | Cadena | Nombre de la carrera |
| `city` | Cadena | Ciudad |
| `country` | Cadena | País |
| `date` | Cadena | Fecha en formato `AAAA-MM-DD` |
| `distance` | Número | Distancia en kilómetros |

**DynamoDB no impone esquema.** La coherencia de esta estructura la garantiza el
código de la API, no el motor de base de datos. Es una diferencia sustancial
respecto a un sistema relacional: la responsabilidad se traslada al
desarrollador.

### Limitación estructural

Con una única clave de partición y sin índices secundarios, **la única consulta
eficiente es recuperar una carrera por su `id`.** Cualquier búsqueda por ciudad,
país, fecha o distancia obliga a usar la operación `Scan`, que recorre la tabla
completa y descarta después.

Aplicar un `FilterExpression` **no reduce la lectura**, solo el volumen de datos
transferido: el coste y la latencia crecen linealmente con el tamaño de la tabla.

Para el volumen del proyecto es irrelevante. Para que las búsquedas escalaran
habría que definir índices secundarios globales (GSI) por los atributos
consultados. El análisis completo está en `docs/architecture.md`, apartado 2.7, y
en la memoria, apartado 4.3.

---

## Diseño inicial: PostgreSQL en RDS

El planteamiento original del proyecto contemplaba un modelo relacional sobre
Amazon RDS, con tres tablas:

| Tabla | Contenido previsto |
|---|---|
| `races` | Datos de las carreras |
| `users` | Usuarios registrados |
| `favorites` | Relación entre usuarios y carreras |

Los circuitos en formato GPX o GeoJSON se almacenarían en S3, guardando en la
base de datos únicamente la referencia:

```text
s3://upc-halfmarathon-routes-dev/barcelona-2027.geojson
```

### Por qué se cambió

El equipo decidió trabajar con un modelo NoSQL no tratado en las sesiones
teóricas, para ampliar el alcance formativo del proyecto. A ello se añadió que
DynamoDB es completamente gestionado y su facturación bajo demanda evita pagar
capacidad reservada durante los periodos de inactividad, circunstancia relevante
con crédito de laboratorio limitado.

### Valoración retrospectiva

Conviene documentarlo con honestidad: **el patrón de acceso real de la
aplicación —búsquedas por múltiples atributos ajenos a la clave— encaja mejor con
un modelo relacional que con DynamoDB.** Un `WHERE city = 'Madrid'` sobre una
columna indexada resuelve en un sistema relacional lo que aquí exige recorrer la
tabla entera.

La elección se sostiene por su valor formativo y por sus ventajas operativas en
el contexto del proyecto, pero no por su adecuación al caso de uso.

Del diseño inicial tampoco llegaron a implementarse las tablas `users` y
`favorites`: la autenticación quedó fuera de alcance.

---

## Archivos de esta carpeta

| Archivo | Estado | Contenido |
|---|---|---|
| `schema.sql` | **Histórico, no ejecutable** | Definición de tablas del modelo relacional inicial |
| `seed.sql` | **Histórico, no ejecutable** | Datos de ejemplo en SQL |
| `seed-races.ps1` | **En uso** | Carga datos de ejemplo llamando a la API |

Los dos archivos SQL **no son ejecutables sobre la implementación actual**:
DynamoDB no utiliza SQL. Se conservan deliberadamente como documentación del
diseño inicial, para que la evolución del modelo quede registrada en el
repositorio y no solo en la memoria.

`seed-races.ps1` es el equivalente funcional de `seed.sql` para la
implementación real. Carga doce carreras mediante peticiones `POST` a la API:

```powershell
.\seed-races.ps1 -ApiUrl "http://<url-del-alb>"
```

---

## Carga automática de datos

Existe además una vía de importación periódica: la función Lambda
`lambdas/import-races`, que se ejecuta semanalmente, lee un fichero JSON desde el
bucket de S3 e inserta en esta tabla las carreras que no existan todavía.

La deduplicación se realiza por **nombre y fecha**, de modo que el proceso es
idempotente y puede repetirse sin generar duplicados.

Detalles en `lambdas/import-races/README.md`.

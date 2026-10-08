# Lambda import-races

Función Lambda de importación periódica de carreras. **Implementada.**

## Flujo real

El planteamiento inicial preveía un CSV que disparara un evento de S3 e
insertara en RDS. La implementación difiere en tres puntos: el formato es JSON,
el disparador es una programación de EventBridge en lugar de un evento de S3, y
el destino es DynamoDB, coherentemente con la base de datos que finalmente se
utilizó en el proyecto.

```text
EventBridge (semanal, lunes 06:00 UTC)
  ↓
Lambda import-races
  ↓
Lee imports/races.json del bucket de S3
  ↓
Consulta qué carreras ya existen en DynamoDB
  ↓
Inserta únicamente las nuevas
  ↓
Publica un resumen en SNS (correo)
  ↓
El frontend las muestra en la siguiente carga
```

Se optó por una programación periódica en lugar de un evento de S3 porque la
importación es un proceso de sincronización, no una reacción a la subida de un
fichero: interesa que se ejecute con regularidad aunque el fichero no haya
cambiado, y que sea seguro repetirla.

## Idempotencia

Dos carreras se consideran la misma si coinciden su **nombre y su fecha**. La
función puede ejecutarse tantas veces como se quiera sin duplicar datos.

Es un requisito imprescindible en un proceso automático que nadie supervisa: si
EventBridge reintenta una invocación, o si alguien la lanza a mano para probar,
el resultado debe ser el mismo.

## Validación

Se descartan los registros que no traigan nombre, ciudad, país, una fecha en
formato `AAAA-MM-DD` y una distancia numérica mayor que cero. Los descartados se
enumeran en el resumen, de modo que un fichero mal formado se detecta sin tener
que revisar los logs.

Nótese que **esta validación es más estricta que la de la propia API**, que no
valida el cuerpo de las peticiones. Es una incoherencia conocida del proyecto,
recogida en el análisis de seguridad de la memoria.

## Cómo probarla

**1. Sube el fichero de ejemplo al bucket:**

```powershell
aws s3 cp lambdas/import-races/ejemplo-races.json s3://marathon-cloudupc-website/imports/races.json
```

**2. Invócala a mano, sin esperar al lunes:**

```powershell
aws lambda invoke --function-name marathon-import-races respuesta.json
Get-Content respuesta.json
```

Debe devolver:

```json
{"ok":true,"importadas":5,"duplicadas":0,"invalidas":0}
```

**3. Lánzala otra vez.** Ahora debe decir `"importadas":0,"duplicadas":5`. Eso
demuestra la idempotencia.

**4. Consulta los logs:**

```powershell
aws logs tail /aws/lambda/marathon-import-races --since 10m
```

**5. Comprueba el resultado en la web:** recarga el frontend, deben aparecer las
cinco carreras nuevas.

## Configuración

Se define en `backend/infra/lambda.tf`:

| Variable de entorno | Contenido |
|---|---|
| `TABLE_NAME` | Nombre de la tabla de DynamoDB |
| `BUCKET_NAME` | Bucket del proyecto |
| `IMPORT_KEY` | Ruta del fichero, por defecto `imports/races.json` |
| `SNS_TOPIC_ARN` | Tema de alertas, vacío si `enable-alarms = false` |

Para cambiar la frecuencia, la variable `lambda-schedule`. Para desactivar la
función por completo, `enable-lambda = false`.

## Formato del fichero

Un array de objetos, como en `ejemplo-races.json`:

```json
[
  {
    "name": "Mitja Marató de Granollers",
    "city": "Granollers",
    "country": "Spain",
    "date": "2027-02-07",
    "web": "https://ejemplo.com",
    "distance": 21.0975
  }
]
```

## Nota de arquitectura

**La función se ejecuta fuera de la VPC**, a diferencia del backend.

Ubicarla en la subred privada obligaría a añadir VPC endpoints de tipo Interface
para SNS y para Lambda, con su coste por hora y por zona de disponibilidad.
Fuera de la VPC alcanza S3, DynamoDB y SNS por sus interfaces públicas
utilizando las credenciales del rol, sin coste adicional de red.

El compromiso es aceptable porque la función no accede a ningún recurso privado,
solo a servicios gestionados. El backend, que sí necesita aislamiento por ser
accesible desde internet, permanece en la subred privada.

No tiene dependencias externas: el SDK de AWS v3 viene incluido en el runtime de
Node.js de Lambda, por lo que no hay `node_modules` que empaquetar.

## Owner

Javi + Miquel, con documentación de Itzel. Implementación de la infraestructura
y de la función: Itzel.

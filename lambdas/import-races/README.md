# Lambda import-races

Función Lambda opcional para importar carreras desde un archivo CSV subido a S3.

## Flujo previsto

```text
CSV subido a S3
  ↓
S3 Event
  ↓
Lambda import-races
  ↓
Inserta carreras en RDS
  ↓
Backend devuelve nuevas carreras
  ↓
Frontend las muestra

#Owner

Javi + Miquel, con documentación de Itzel.

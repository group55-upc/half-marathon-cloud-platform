# Architecture

## Visión general

La aplicación permite consultar medias maratones desde una web. El usuario accede al frontend, busca carreras y la web llama a una API. La API consulta una base de datos PostgreSQL en Amazon RDS y devuelve los resultados.

## Flujo principal

```text
Usuario
  ↓
Route 53
  ↓
CloudFront
  ↓
S3 frontend
  ↓
React
  ↓
ALB / Ingress
  ↓
EKS / Kubernetes
  ↓
Backend API
  ↓
RDS PostgreSQL

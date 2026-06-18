# Backend API

API REST desarrollada con Node.js + Express.

## Owner

Javi

## Endpoints previstos

```text
GET /races
GET /races/:id
GET /races?city=Barcelona
GET /races?date=2027-02
POST /races
GET /health

Conexión con base de datos
La API se conectará a PostgreSQL usando variables de entorno:
DB_HOST
DB_NAME
DB_USER
DB_PASSWORD
DB_PORT

Docker
El backend se empaquetará con Docker usando:
backend/Dockerfile


# Database

Modelo de datos del proyecto.

## Owner

Miquel

## Base de datos

PostgreSQL en Amazon RDS.

## Tablas

- races
- users
- favorites

## Qué se guarda en RDS

RDS guarda datos estructurados de las carreras:

- nombre
- ciudad
- país
- fecha
- distancia
- web oficial
- referencia al circuito

## Qué se guarda en S3

Los circuitos GPX/GeoJSON se guardan en S3.

En RDS solo se guarda la referencia:

```text
s3://upc-halfmarathon-routes-dev/barcelona-2027.geojson

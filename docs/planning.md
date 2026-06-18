# Project Planning

## Objetivo

Planificar el desarrollo de la plataforma Half Marathon Cloud Platform.

## Stack

- Frontend: React + Vite
- Backend/API: Node.js + Express
- Base de datos: PostgreSQL en Amazon RDS
- Infraestructura: Terraform
- Contenedores: Docker
- Registro de imágenes: Amazon ECR
- Orquestación: Amazon EKS + Kubernetes
- Almacenamiento: Amazon S3
- Monitorización: Amazon CloudWatch

## Roles

| Persona | Rol | Responsabilidades |
|---|---|---|
| Itzel | Technical Project Lead + Kubernetes | Coordinación, documentación, Kubernetes e integración |
| Javi | Backend Lead | API Node.js + Express, conexión PostgreSQL, Dockerfile |
| Xavi | Frontend Lead | React, pantallas, buscador e integración con API |
| Miquel | Data Lead | Modelo de datos, RDS, S3 routes y datos de prueba |
| Oscar | Cloud Infrastructure Lead | Terraform, AWS, ECR, EKS, IAM y CloudWatch |

## Cronograma

| Fechas | Objetivo | Owner |
|---|---|---|
| 1–5 julio | Definición del proyecto, stack y arquitectura | Itzel + todos |
| 6–12 julio | Modelo de datos + backend base | Miquel + Javi |
| 13–19 julio | Backend conectado a PostgreSQL | Javi + Miquel |
| 20–26 julio | Frontend conectado a API local | Xavi + Javi + Itzel |
| 27 julio–2 agosto | Docker + S3/ECR base | Javi + Oscar + Itzel |
| 3–9 agosto | Infraestructura AWS con Terraform | Oscar |
| 10–16 agosto | EKS + Kubernetes | Itzel + Oscar + Javi |
| 17–23 agosto | Integración final frontend + backend + AWS | Xavi + Itzel + Oscar |
| 24–31 agosto | Mejoras, documentación y demo | Itzel + todos |
| 1 septiembre | Revisión final | Todos |

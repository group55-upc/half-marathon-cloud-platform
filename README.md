# Half Marathon Cloud Platform
Plataforma web cloud-native para consultar medias maratones.

## Objetivo
El objetivo del proyecto es construir una aplicación web que permita buscar medias maratones por ciudad o fecha, consultar la información de cada carrera y visualizar su circuito.

## Stack tecnológico
- Frontend: React + Vite
- Backend/API: Node.js + Express
- Base de datos: PostgreSQL en Amazon RDS
- Almacenamiento: Amazon S3
- Contenedores: Docker
- Registro de imágenes: Amazon ECR
- Orquestación: Amazon EKS + Kubernetes
- Infraestructura como código: Terraform
- Monitorización: Amazon CloudWatch
- Opcional: Lambda + EventBridge
- Opcional: CI/CD + Trivy
- Opcional: Amazon Bedrock para bot IA

## Estructura del repositorio
- frontend/                 # Aplicación web React
- backend/                  # API Node.js + Express
- database/                 # Scripts SQL y modelo de datos
- infrastructure/terraform/ # Infraestructura AWS con Terraform
- kubernetes/               # Manifests Kubernetes para EKS
- lambdas/                  # Funciones Lambda opcionales
- docs/                     # Documentación del proyecto
- .github/workflows/        # Pipelines CI/CD opcionales

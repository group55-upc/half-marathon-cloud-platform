# ☁️ Módulo de Infraestructura AWS

Este directorio contiene la arquitectura de infraestructura como código (IaC) desarrollada en **Terraform** para la plataforma de la Media Maratón.

---

## 🛠️ Componentes de la Infraestructura

El código modularizado incluye los siguientes componentes principales en AWS:

* **Redes (VPC):** Configuración de la red virtual (`vpc.tf`) para aislar los recursos del proyecto de forma segura.
* **Almacenamiento (S3):** Bucket de Amazon S3 (`s3.tf`) configurado para alojar activos estáticos o datos de la plataforma.
* **Base de Datos (DynamoDB):** Tabla NoSQL (`dynamodb.tf`) para almacenamiento rápido y escalable de datos.
* **Variables y Parámetros:** Definición de variables reutilizables (`variables.tf`) y salidas estructuradas (`outputs.tf`).

---

## 📂 Estructura del Módulo

```text
oscar/
├── provider.tf           # Configuración del proveedor de AWS
├── vpc.tf                # Configuración de red (VPC, Subnets)
├── s3.tf                 # Buckets de almacenamiento S3
├── dynamodb.tf           # Tablas de base de datos DynamoDB
├── variables.tf          # Declaración de variables de entrada
├── outputs.tf            # Valores de salida de los recursos
└── README.md             # Documentación del módulo

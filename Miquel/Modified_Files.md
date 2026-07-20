# Modified Files

## Author

**Miquel Arjol Marco**

---

# Introduction

This document describes the files that were created or modified during the development of the **Half Marathon Cloud Platform** as part of the Master's Thesis (TFM).

The objective of these developments was to transform the original application into a cloud-native solution deployed automatically on Amazon Web Services (AWS) using Infrastructure as Code (Terraform).

The implementation includes:

- AWS infrastructure deployment
- Automatic backend deployment
- REST API implementation
- Amazon DynamoDB integration
- Angular frontend integration
- Infrastructure automation
- Health monitoring

---

# Backend

## server.js

### Purpose

Main Express application responsible for exposing the REST API.

### Modifications

- Added Health Check endpoint (`/health`)
- Added REST endpoint to retrieve races (`GET /races`)
- Added REST endpoint to create races (`POST /races`)
- Added DynamoDB integration
- Added startup validation
- Added error handling
- Configured CORS support

### Contribution

Provides the application services consumed by the Angular frontend.

---

## db.js

### Purpose

Database access layer.

### Modifications

- Configured AWS SDK v3
- Connected to Amazon DynamoDB
- Added database connectivity validation
- Implemented race retrieval
- Implemented race creation
- Added error handling

### Contribution

Allows the backend to store and retrieve race information from DynamoDB.

---

## package.json

### Purpose

Node.js dependency management.

### Modifications

Added required libraries including:

- Express
- AWS SDK v3
- CORS
- UUID

---

# Frontend

## src/app/services/race.service.ts

### Purpose

Service responsible for communication with the backend API.

### Modifications

- Added backend API URL
- Implemented GET requests
- Implemented POST requests
- Added HTTP error handling

### Contribution

Allows the Angular application to communicate with the REST API.

---

## Angular Components

### Dashboard Component

Displays all available races obtained from the backend.

### Add Race Component

Allows new races to be created and stored in DynamoDB.

---

# Infrastructure

The infrastructure has been implemented entirely using **Terraform**.

---

## main.tf

Defines the Terraform provider and initializes the project.

---

## variables.tf

Contains all configurable deployment variables.

Examples:

- AWS Region
- CIDR blocks
- EC2 configuration
- SSH key name

---

## network.tf

Creates the AWS networking components.

Resources include:

- VPC
- Public Subnet
- Internet Gateway
- Route Table

---

## security.tf

Creates the Security Groups.

Configured ports include:

- SSH (22)
- HTTP (80)
- Backend API (5000)

---

## ec2.tf

Deploys the backend EC2 instance.

Responsibilities:

- Launch EC2
- Configure IAM Profile
- Configure Security Group
- Configure User Data

---

## iam.tf

Creates the IAM Role and Instance Profile required for DynamoDB access.

---

## dynamodb-endpoint.tf

Creates the VPC Endpoint for DynamoDB.

This allows private communication between the EC2 instance and DynamoDB without traversing the public Internet.

---

## backend-package.tf

Packages the backend application into a ZIP archive before deployment.

---

## backend-deploy.tf

Automatically deploys the backend application to EC2.

Operations performed:

- Upload backend package
- Install dependencies
- Configure Systemd service
- Restart backend service

---

## outputs.tf

Defines useful Terraform outputs including:

- EC2 Public IP
- Backend API URL

---

# Project Architecture

```
Angular Frontend
        │
        │ HTTP REST
        ▼
Node.js / Express API
        │
        ▼
Amazon DynamoDB
```

Infrastructure provisioning is fully automated using Terraform.

---

# Summary of Contributions

The following capabilities were implemented during this development:

- Infrastructure as Code (Terraform)
- Complete AWS deployment
- REST API implementation
- DynamoDB integration
- Automatic backend deployment
- Angular integration
- Health monitoring endpoint
- Infrastructure automation
- Cloud-native architecture

These developments provide an automated deployment process while maintaining a modular, scalable and maintainable architecture.

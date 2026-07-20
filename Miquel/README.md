# Half Marathon Cloud Platform - Personal Development

## Author

Miquel Arjol Marco

## Description

This folder contains all personal developments implemented during the Master's Thesis (TFM).

The implementation extends the original project by adding a complete cloud deployment on AWS using Infrastructure as Code (Terraform).

## Main Features

- Node.js + Express REST API
- DynamoDB integration
- AWS SDK v3
- Angular frontend
- Terraform Infrastructure as Code
- VPC
- Security Groups
- EC2 automatic deployment
- Backend automatic deployment
- DynamoDB VPC Endpoint
- Systemd backend service
- Health endpoint
- Race management REST API

## Project Structure

```
backend/
frontend/
infrastructure/
```

## Deployment

### 1. Configure AWS credentials

```bash
source ~/aws-creds.sh
```

### 2. Update terraform.tfvars

Update:

- allowed_cidr
- SSH Key
- AWS Region

### 3. Deploy Infrastructure

```bash
terraform init
terraform apply
```

### 4. Start Angular

```bash
cd frontend/Frontend
npm install
npm start
```

Open:

```
http://localhost:4200
```

## Backend Health

```
http://<EC2_PUBLIC_IP>:5000/health
```

## Backend API

```
GET /races
POST /races
GET /health
```

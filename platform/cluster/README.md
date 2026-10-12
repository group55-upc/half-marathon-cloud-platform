## REQUERIMENTS

Credencials aws configurades a ~/.aws/credentials

Bucket S3 amb nom s3-cloudfpc-state per al .tfsate

Context del clúster eks

## OBTENIR CONTEXT DEL CLÚSTER EKS

Amb les credencials configurades a ~/.aws/credentials

Mirem si registrats

```
aws sts get-caller-identity
```

Obtenim el context i el guardem al fitxer ~/.kube/config per defecte
```
aws eks update-kubeconfig --region <region> --name <cluster-name> --kubeconfig ~/.kube/config
```

## ENTORN DE TREBALL 

Inicialitzar configuració

```
terraform init
```

Inicialitzar configuració sense backend

```
terraform init -backend=false
```

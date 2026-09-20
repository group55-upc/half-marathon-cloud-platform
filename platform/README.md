# PLATFORM

El directori infrastructure conté el codi de Terraform que s'ecnarrega de gestionar la infraestructura cloud generica, load balancers, vpc, clusters eks, etc

El directori cluster conté el codi de Terraform que gestiona recursos de kubernetes, en aquest cas de l'únic clúster EKS del que disposem.

### INFRASTRUCTURE

`alb.tf`:

`amplify.tf`:

`autoscaling.tf`:

`backend.tf`:

`cert.tf`:

`cloudwatch.tf`:

`dynamodb.tf`:

`ecr.tf`:

`eks.tf`:

`endpoints.tf`:

`lambda.tf`:

`routing.tf`:

`s3.tf`:

`sg.tf`:

`sns.tf`:

`vpc.tf`:

`control.auto.tfvars`:

`data.tf`:

`outputs.tf`:

`providers.tf`:

`backend.tf`:

### CLUSTER

Conté els següents fitxers:

`backend.tf`: Configuració del backend cap a un bucket S3 remot

`providers.tf`: Configuració dels providers necessaris, en aquest cas kubernetes i helm

`data.tf`: Blocs de data que utilitza la configuració de Terraform

`variables.tf`: Variables que s'utilitzen als diferents recursos de la configuració de Terraform

`control.auto.tfvars`: Declaració del valors de les diferents variables definides al fitxer variables.tf

`k8s-platform.tf`: Recursos de kubernetes relatius al clúster, no conté aplicacions d'usuari, si no de plataforma

`k8s-app.tf`: Recursos de kubernetes relatius a aplicacions d'usuaris

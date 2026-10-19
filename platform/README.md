# PLATFORM

El directori _platform_ conté dos subdirectoris, _infrastructure_ i _cluster_

El directori _infrastructure_ conté la configuració de Terraform que gestiona la infraestructura cloud genèrica, load balancers, vpc, clústers eks, etc. A continuació es llisten els fitxers i que conté cadascun

El directori _cluster_ conté la configuració de Terraform que gestiona recursos de kubernetes dins del clúster eks. És on es defineixen recursos com deployments, configmaps, o els helm releases de les nostres aplicacions. Aquesta configuració **no** gestiona la infraestructura del clúster (nodes, xarxa, etc), únicament gestiona components de kubernetes

### INFRASTRUCTURE

Conté els següents fitxers:

`alb.tf`: Configuració que defineix el Aplication Load Balancer, com també el Target Group i els Listeners de http i https

`amplify.tf`: Configuració del frontend de l'aplicació _marathon-app_ desplegat amb amplify. Defineix l'aplicació, el domini dns i dues branques relacionades amb el GitHub, _main_ i _des_

`autoscaling.tf`: Fitxer on es defineixen les polítiques d'autoescalat dels nodes workers del clúster eks. Hi ha dues, una relacionada amb l'ús de cpu i l'altre amb l'ús de memòria

`cert.tf`: Configuració del Amazon Cert Manager per generar un certificat per al alias dns que apunta al nom dns del alb

`cloudwatch.tf`: Alarmes de monitoratge dels nodes workers del clúster eks. Hi ha dues, una relacionada amb l'ús de cpu i l'altre amb l'ús de memòria

`cognito.tf`: Definició del _AWS User Pool_ que utilitza l'aplicació marathon-app. Conté la definició de la _pool_ d'usuaris i del client _marathon-app_

`dynamodb.tf`: Configuració de les bases de dades de l'aplicació _marathon-app_

`ecr.tf`: Configuració del registry privat on publicar imatges de contenidors

`eks.tf`: Configuració del clúster eks, dataplane, worker nodes i diferents accessos

`endpoints.tf`: Configuració dels vpc endpoints per permetre cert tipus de tràfic dins les subxarxes privades

`lambda.tf`: Funció de l'aplicació _marathon-app_ per notificar als usuaris quan s'ha públicat una nova cursa

`route53.tf`: Configuració de la subzona delegada del Route53 i de l'aliàs del nom dns del alb

`s3.tf`: Bucket d'emmagatzematge de les curses de l'aplicació marathon-app

`secretmanager.tf`: Definició dels secrets que utilitza l'aplicació _marathon-app_. Concretament, els necessaris per accedir a la _pool_ d'usuaris de AWS Cognito

`sg.tf`: Configuració dels diferents security groups dins la vpc

`sns.tf`: Tòpic i subscripció per rebre notificacions quan salten les alarmes de cloudwatch, així com tòpic per notificar als usuaris de les noves curses de l'aplicació _marathon-app_

`vpc.tf`: Configuració de xarxa, vpc, subxarxes, nat, etc

`data.tf`: Recursos de data per obtenir informació sobre infraestructura existent, sobretot relacionada amb el LabRole

`outputs.tf`: Definició de diferents ouputs relacionats, sobretot, amb accessos web

`providers.tf`: Definició i configuració dels _providers_ necessaris per a la configuració, en aquest cas _aws_

`backend.tf`: Configuració del bloc de backend de Terraform, apunta a un s3

`variables.tf`: Definició de les variables utilitzades 

`control.auto.tfvars`: Declaració dels valors personalitzats de les variables definides a _variables.tf_

### CLUSTER

Conté els següents fitxers:

`backend.tf`: Configuració del bloc de backend de Terraform, apunta a un s3

`providers.tf`: Definició i configuració dels _providers_ necessaris per a la configuració, en aquest cas _kubernetes_ i _helm_

`variables.tf`: Definició de les variables utilitzades 

`control.auto.tfvars`: Declaració dels valors personalitzats de les variables definides a _variables.tf_

`k8s-platform.tf`: Recursos de kubernetes relatius al clúster, no conté aplicacions d'usuari, si no de plataforma

`k8s-app.tf`: Recursos de kubernetes relatius a aplicacions d'usuaris

### DESPLEGAMENT DE LA INFRAESTRUCTURA

Primer de tot inicialitzar l'entorn de laboratori AWS Academy, un cop inicialitzat copiem les credencials a
```
~/.aws/credentials
```

Accedim via web a la consola de AWS Academy i creem un bucket amb el nom _s3-cloudfpc-state_ per emmagatzemar els .tfstate

Amb el bucket creat podem començar a desplegar la infraestructura

Primer anirem al directori platform/infrastructure
```
cd half-marathon-cloud-platform/platform/infrastructure
```

Inicialitzem la configuració de Terraform
```
terraform init
```

Un cop inicialitzada la configuració, obrirem el fitxer _control.auto.tfvars_. Dins d'aquest fitxer estan definides les variables de control que ens permeten gestionar la infraestructura de manera modular. Ens asegurem que totes estiguin a _false_

Amb totes les variables de control desactivades, executem Terraform
```
terraform apply -auto-approve
```

El primer _terraform apply_ te una limitació. Al intentar validar el nom DNS del balancejador, com es una subzona delegada, si aquesta no esta configurada, es quedara pendent durant 15 minuts fins que Terraform faci time-out. Quan comenci la validació del DNS del alb _aws_acm_certificate_validation.alb-cluster-cert_ esperarem uns minuts i enviarem una señal de interrupt a Terraform (Ctrl + C).

Contactarem amb el gestor de la subzona del DNS per a que la configuri. Necessitarà els NS que amazon ens ha proporcionat, els podem obtindre executant la següent comanda
```
terraform output route53-nameservers
```

Un cop estigui configurada la subzona, podem tornar a executar Terraform
```
terraform apply -auto-approve
```

Amb la infraestructura base desplegada, podem crear els bloc adicionals gestionats per les variables indicades previament. Modifiquem el fitxer _control.auto.tfvars_
```
enable-eks          = true
enable-autoscaling  = true
enable-alarms       = true
enable-marathon-app = **false**
```

Tornem a executar Terraform per desplegar el clúster EKS, les polítiques d'autoescalat i les alarmes de cloudwatch. Pot tardar fins a **10 minuts** en desplegar el clúster
```
terraform apply -auto-approve
```

Amb el cluster desplegat, podem crear els bloc adicionals relacionats amb la aplicació _marathon-app_. Modifiquem el fitxer _control.auto.tfvars_
```
enable-eks          = true
enable-autoscaling  = true
enable-alarms       = true
enable-marathon-app = true
```

Tornem a executar Terraform
```
terraform apply -auto-approve
```


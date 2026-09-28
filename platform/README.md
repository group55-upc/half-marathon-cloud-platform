# PLATFORM

El directori _platform_ conté dos subdirectoris, _infrastructure_ i _cluster_

El directori _infrastructure_ conté la configuració de Terraform que gestiona la infraestructura cloud genèrica, load balancers, vpc, clústers eks, etc. A continuació es llisten els fitxers i que conté cadascun.

El directori _cluster_ conté la configuració de Terraform que gestiona recursos de kubernetes dins del clúster eks. És on es defineixen recursos com deployments, configmaps, o els helm releases de les nostres aplicacions. Aquesta configuració **no** gestiona la infraestructura del clúster (nodes, xarxa, etc), únicament gestiona components de kubernetes.

### INFRASTRUCTURE

Conté els següents fitxers:

`alb.tf`: Configuració de Terraform relacionada amb el aplication load balancer que s'encarrega d'enviar el tràfic, en aquest cas, al clúster eks

`amplify.tf`: Configuració del frontend de l'aplicació marathon-app desplegat amb amplify

`autoscaling.tf`: Polítiques d'autoescalat dels nodes workers del clúster eks

`cert.tf`: Configuració del Amazon Cert Manager per generar un certificat per al alias dns que apunta al nom dns del alb

`cloudwatch.tf`: Alarmes de monitoratge dels nodes workers del clúster eks

`dynamodb.tf`: Base de dades de l'aplicació marathon-app

`ecr.tf`: Configuració del registry privat on publicar imatges de contenidors

`eks.tf`: Configuració del clúster eks, dataplane, worker nodes i accessos

`endpoints.tf`: Configuració dels vpc endpoints per permetre cert tipus de tràfic dins les subxarxes privades

`lambda.tf`: Funció per importar curses, Itzel

`routing.tf`: Configuració de la subzona delegada del Route53 i aliàs del nom dns del alb

`s3.tf`: Buckets per el frontend de l'aplicació marathon-app i bucket d'emmagatzematge de les curses de l'aplicació marathon-app

`sg.tf`: Configuració dels diferents security groups dins la vpc

`sns.tf`: Tòpic i subscripció per rebre quan salten les alarmes de cloudwatch

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

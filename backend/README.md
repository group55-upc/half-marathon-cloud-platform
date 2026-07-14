# BACKEND

Per muntar el backend actual s'han de seguir els següents passos:

Si voleu provar el backend en local:  [clic aquí](#local)
Si voleu muntar tota la infraestructura: [clic aquí](#cloud)


## CLOUD

Si voleu fer una prova amb tota la primera primeríssima versió del backend

### AWS / TERRAFORM - PART 1

Situarnos al directori corresponent

```bash
cd /half-marathon-cloud-platform/backend/infra
```

Fer un export de les variables de entorn (credencials de aws) a la CLI

```bash
export AWS_ACCESS_KEY_ID=[...]
export AWS_DEFAULT_REGION=us-east-1[...]
export AWS_SECRET_ACCESS_KEY=[...]
export AWS_SESSION_TOKEN=[...]
```

Terraform init

```bash
terraform init
```

Terraform apply per crear la xarxa bàsica, la dynamoDB i el ECR (Container Registry)

```bash
terraform apply
[...]
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Agafem l'output que surt per CLI, és l'URL del ECR

```bash
Outputs:

registry-url = "305229890836.dkr.ecr.us-east-1.amazonaws.com/container-image-repository"
```


### CONSTRUIR LA IMATGE DEL CONTENIDOR

Situarnos al directori corresponent

```bash
cd /half-marathon-cloud-platform/backend/code
```

Crear la imatge

```bash
docker build -t api -f Dockerfile .
```

Mirem si s'ha creat correctament 
```bash
docker image list

IMAGE                                                                                  ID             DISK USAGE   CONTENT SIZE   EXTRA
api:latest                                                                             8a1dce03827f        456MB         96.7MB        
```

Guardem les credencials del registry en local, modifiqueu la URL per la que toqui del ECR (anterior output de terraform, sense cap path)

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 305229890836.dkr.ecr.us-east-1.amazonaws.com
```

Afegim la tag amb la URL del repositori a la imatge del contenidor

```bash
docker tag api:latest 305229890836.dkr.ecr.us-east-1.amazonaws.com/container-image-repository:v1.0
```

Pugem la imatge al repositori

```bash
docker push 305229890836.dkr.ecr.us-east-1.amazonaws.com/container-image-repository:v1.0
```

Aquests passos els podeu trobar via web a AWS, dins del registre de ECR. Hi ha un botó taronja anomenat VIEW PUSH COMMANDS, per si us és més fàcil.


### AWS / TERRAFORM - PART 2

Ara que ja tenim la imatge al ECR, farem MÀGIA!

Ens situem al directori corresponent

```bash
cd /half-marathon-cloud-platform/backend/infra
```

Modificarem el fitxer backend.auto.tfvars
```bash
enable-ECS = false <- Ho fiquem a true
```

Terraform init
```bash
terraform init
```

Terraform apply
```bash
Terraform apply
[...]
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

[...]
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

Amb això haurem creat el clúster ECS, la task i el service amb el contenidor del backend executant-se.

Anem a AWS via web -> ECS -> Clusters -> half-marathon-cluster -> Tasks -> Fem clic a l'única que hi ha -> Networking -> Copiem la IP pública.

Al navegador, podem buscar el següent (Modifiqueu amb la IP corresponent)

```bash
http://<IP>:5000/   ->  status	"ok"
```

```bash
http://<IP>:5000/connection   ->  status	"ok"
```
Si executem el següent curl a la CLI i fem una cerca http al navegador

```bash
curl -X POST http://<IP>:5000/races \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Madrid Marathon",
    "city": "Madrid",
    "country": "Spain",
    "date": "2026-03-15",
    "web": "https://madridmarathon.com",
    "distance": 42
  }'
```

```bash
http://<IP>:5000/races
	
0	
city	"Madrid"
web	"https://madridmarathon.com"
date	"2026-03-15"
distance	42
id	"1784066364063-9462"
country	"Spain"
name	"Madrid Marathon"

```
*THE END*

Per eliminar tot

Terraform
```bash
terraform destroy
[...]
Plan: 0 to add, 0 to change, 12 to destroy.

Changes to Outputs:
  - registry-url = "305229890836.dkr.ecr.us-east-1.amazonaws.com/container-image-repository" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```
Imatges docker
```bash
docker image list

docker image rm <ID>
```

## LOCAL

Si voleu fer proves en local sense haver de muntar tota la infraestructura a AWS, podeu fer el següent.
És important que desfeu els canvis si voleu fer proves amb tota la infraestructura, sobretot del codi de l'api.

### DYNAMODB

Dins la consola AWS -> DynamoDB -> Create Table:

```
Table name: races
Partition key: id (string)
Sort key: -- ()
```

La resta de la configuració per defecte


### NODEJS

Instal·lar nodejs:

```bash
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v # Should print "v24.16.0".

# Verify npm version:
npm -v # Should print "11.13.0".
```

Instal·lar les dependencies

```bash
npm install
```

Crear el fitxer .env i afegir les credencials de AWS. Important sense "" i sense espais. Ex:

```bash
AWS_ACCESS_KEY_ID=AEIOU12345
AWS_SECRET_ACCESS_KEY=12345AEIOU
AWS_SESSION_TOKEN=12345TOKENAEIOU
AWS_REGION=us-east-1
```

Modificar el fitxer db.js

```bash
const connection = new DynamoDBClient({
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    sessionToken: process.env.AWS_SESSION_TOKEN
  }
});

```

Descomentar la seguent linea dels fitxers server.js i db.js

```bash
//require("dotenv").config();
```

Iniciar el backend

```bash
npm start
```

Fixeu-vos que escolta pel port 5000 (http://localhost:5000). Si voleu modificar el port, heu de modificar la següent línia del fitxer server.js

```bash
const port = 5000; <-- Indiqueu el port que vulgueu
```
*THE END*
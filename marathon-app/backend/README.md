# BACKEND

Codi del contenidor que actua com a backend a l'aplicació de marathon

### CONSTRUIR LA IMATGE DEL CONTENIDOR

Situarnos al directori corresponent

```bash
cd /half-marathon-cloud-platform/backend/code
```

Crear la imatge

```bash
docker build -t marathon-backend -f Dockerfile .
```

Mirem si s'ha creat correctament 
```bash
docker image list

IMAGE                                                                                  ID             DISK USAGE   CONTENT SIZE   EXTRA
marathon-backend:latest                                                                             8a1dce03827f        456MB         96.7MB        
```

Guardem les credencials del registry en local, modifiqueu la URL per la que toqui del ECR (anterior output de terraform, sense cap path)

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <URL Registry ECR>
```

Afegim la tag amb la URL del repositori a la imatge del contenidor

```bash
docker tag marathon-backend:latest <URL Registry ECR>/container-image-repository:v1.0
```

Pugem la imatge al repositori

```bash
docker push <URL Registry ECR>/container-image-repository:v1.0
```

Aquests passos els podeu trobar via web a AWS, dins del registre de ECR. Hi ha un botó taronja anomenat VIEW PUSH COMMANDS, per si us és més fàcil.


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

Iniciar el backend

```bash
npm start
```

Fixeu-vos que escolta pel port 5000 (http://localhost:5000). Si voleu modificar el port, heu de modificar la següent línia del fitxer server.js

```bash
const port = 5000; <-- Indiqueu el port que vulgueu
```

### TREBALLAR EN LOCAL

Per poder fer proves del codi amb els serveis cloud de AWS, heu de fer les següents modificacions

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

Afeegir la seguent linea dels fitxers server.js, db.js i s3.js

```bash
require("dotenv").config();
```

Instal·lar les dependencies

```bash
npm install
```

Iniciar el backend

```bash
npm start
```
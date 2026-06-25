## BACKEND

### AWS

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

Iniciar el backend

```bash
npm start
```

Fixeu-vos que escolta pel port 5000 (http://localhost:5000). Si voleu modificar el port, heu de modificar la següent línia del fitxer server.js

```bash
const port = 5000; <-- Indiqueu el port que vulgueu
```

### PART DE DOCKER, NO ÉS NECESSÀRIA DE MOMENT
No funcionarà per tema de credencials

Crear la imatge

```bash
docker build -t backend-nodejs
```

Executar el contenidor

```bash
docker run -d -p 5000:5000 --name my-api backend-nodejs:latest
```
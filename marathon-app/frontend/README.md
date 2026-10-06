# BACKEND

Codi del frontend de l'aplicació de marathon

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

Iniciar el frontend

```bash
npm start
```


## Instal·lacio de l'entorn de Node.js i les dependències

`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash`

En aquest punt reiniciar la shell

Instal·la Node.js versió 24
`nvm install 24`

`node -v` 
Should print "v24.16.0".

`npm -v` 
Should print "11.13.0".

Instal·la les dependències. S'ha d'executar des del directori que conté el Backend, que haurem descarregat prèviament, el qual conté el fitxer package.json, doncs és aquest arxiu el que conté les dependències.
`npm install`


Per arrancar el Backend en local es farà servir, des de la carpeta local amb el Backend (en el meu cas ***$HOME/posgrado_tfp/Backend***)
`npm start`

Aquest comando mira al fitxer package.json i executa l'script indicat a l'apartat **"start": "node server.js"**. És aquest el que arranca Node.js executant el Backend.



Nota: abans d'arrancar Node.js he hagut de crear la BD a DynamoDB segons les especificacions d'en Javier.

Nota: Abans d'arrancar Node.js cal arrancar l'entorn de Lab d'AWS a on tenim la BD DynamoDB, i cal actualitzar les credencials d'AWS al fitxer ocult .env (recordar que canvien cada cop que iniciem el AWS Lab)



# Context pel Frontend

Primer de tot he creat un directori de treball pel Frontend:
***$HOME/posgrado_tfp/Frontend***

Em posiciono en aquest directori per a realitzar la resta d'operacions.

He instal·lat el CLI d'Angular:
`npm install -g @angular/cli`


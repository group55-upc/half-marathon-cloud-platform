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

Un cop instal·lat comprobo que està bé mirant la versió d'Angular:
`ng version`

I a continuació he creat un nou projecte. L'he anomenat Frontend:
`ng new Frontend`

Abans de seguir he hagut de fer una noficació de seguretat per a permetre que el Frontend s'hi pugui parlar amb el Backend a través de ports diferents. Al fitxer server.js del Backend he afegit la següent fila al mig d'aquest bloc de configuració ja existent:

> const port = 5000;
> // --- AQUÍ DEBEN IR LOS MIDDLEWARES ---
> app.use(cors()); // 2. ¡JUSTO AQUÍ! Activa CORS para todas las rutas obligatoriamente
> //-------------------------------------------
> app.use(express.json());


I a continuació he instal·lat el paquet CORS:
`npm install cors`

Al tornar a arrancar el Node.js del Backend ja ha agafat aquest canvi.


Un cop creat el Frontend, per arrancar-lo dins del contexte d'execució d'Angular, cal entrar dins de la carpeta del Frontend i executar ng serve (ng és el comando d'Angular):
`~/posgrado_tfp/Frontend/Frontend$ ng serve`

Aquest context d'execució és el que es fa servir durant el desenvolupament d'Angular, que fa servir Typescript. Un cop tenim el projecte acabat, s'ha de compilar per a transformar-lo en quelcom que un navegador web pot interpretar (HTML5, CSS i Javascript). La compilació l'ha fet automàticament (ng build), i el resultat el deixa dins de la carpeta ***dist*** del projecte del Frontend.

Per provar el correcte funcionament del Frontend fora del context d'Angular he instal·lat Apache al meu Linux.

## Prova del Frontend compilat amb Linux

Instal·lació d'Apache (faig servir Xubuntu):
`sudo apt update`
`sudo apt install apache2`

Amb un navegador comprovo que s'estigui fent servir correctament:
http://localhost

Esborro la pàgina per defecte:
`sudo rm /var/www/html/index.html`

Copio la web estàtica compilada:
`sudo cp -r dist/Frontend/browser /var/www/html`

I faig alguns canvis més perquè funcioni bé fent click als components, en tractar-se d'una SPA:

`sudo a2enmod rewrite`

Crea un arxiu .htaccess dins la carpeta de la app:
`sudo nano /var/www/html/.htaccess`
Enganxa el següent codi dins d'aquest arxiu (li diu a Apache que redirigeixi tot a l'index.html):

Apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>

Ara perque ho tingui en compte cal modificar el fitxer /etc/apache2/apache2.conf

Cal buscar la secció que es refereix a /var/www i canviar AllowOverride None per AllowOverride All. Ha de quedar així:

Apache
<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>

Reiniciar apache perquè apliqui els canvis:
`sudo systemctl restart apache2`

I el Frontend ja ha d'estar disponible a:
http://localhost
servit per Apache, fora del context de desenvolupament d'Angular.
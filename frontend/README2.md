# Instal·lació de l'entorn pel Backend

He creat un directori al meu portàtil a on he get un git clone del projecte.

Aleshores he creat un directori a banda a on he copiat els arxius del Backend descarregats de Github:
***$HOME/posgrado_tfp/Backend***



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



>Notes generades per Gemini al respecte del Backend:

¡Perfecto! Ya tenemos los archivos sobre la mesa. Tienes un backend desarrollado en Node.js usando el framework Express, y su objetivo principal es gestionar un listado de carreras (races), probablemente de atletismo, ciclismo o maratones.

Como base de datos, utiliza Amazon DynamoDB (una base de datos NoSQL en la nube de AWS).

Aquí tienes el análisis completo de qué hace este backend y cómo está estructurado.

🗺️ Arquitectura General de los Archivos
package.json: Contiene la configuración del proyecto y sus dependencias. Usa Express para el servidor y los SDKs de AWS (@aws-sdk/client-dynamodb y @aws-sdk/lib-dynamodb) para conectarse a la base de datos.

db.js: Se encarga exclusivamente de configurar la conexión con Amazon DynamoDB utilizando variables de entorno para las credenciales de AWS (accessKeyId, secretAccessKey, etc.).

server.js: Es el núcleo de la aplicación. Levanta el servidor en el puerto 5000 y define los endpoints (las rutas) de la API Rest.

🌐 Endpoints Disponibles (La API Rest)
La API cuenta actualmente con tres endpoints principales que interactúan con una tabla de DynamoDB llamada "races". Los atributos de cada carrera son: id, name, city, country, date, web, y distance.

1. GET /races (Obtener carreras)
Es un endpoint bastante inteligente y flexible. Funciona de tres formas diferentes según los parámetros que le pases en la URL:

Sin parámetros (/races): Devuelve todas las carreras de la base de datos. Tiene implementado un bucle (do...while) con ExclusiveStartKey para asegurarse de traer todos los registros si la base de datos supera el límite de 1MB por respuesta que tiene DynamoDB.

Por ID (/races?id=VALOR): Si solo le pasas el ID, utiliza un método directo y rápido (GetCommand) para buscar esa carrera específica. Si no existe, devuelve un error 404.

Por filtros (/races?country=Spain&distance=42): Si le pasas cualquier otro parámetro, construye dinámicamente un filtro para buscar coincidencias exactas en la base de datos.

2. POST /races (Crear una carrera)
Sirve para registrar una nueva carrera en el sistema.

Espera recibir un JSON en el cuerpo de la petición con los datos de la carrera.

Como las bases de datos NoSQL no suelen autogenerar IDs incrementales, el desarrollador creó un generador de IDs propio combinando el timestamp actual con un número aleatorio: ${Date.now()}-${Math.floor(Math.random() * 10000)}.

Si todo sale bien, guarda la carrera y responde con { "status": "ok" }.

3. GET /health (Verificación de estado)
Es una ruta típica de "salud" del sistema. Intenta hacer una consulta mínima (límite 1 elemento) a la base de datos. Si responde bien, devuelve { "status": "ok" }. Sirve para que sistemas externos sepan si el servidor y la base de datos están corriendo sin problemas.

📝 Notas de desarrollo encontradas (Comentarios en el código)
El desarrollador dejó varias notas en catalán y español sobre cosas pendientes o cómo funciona el código:

Seguridad: Tiene desactivado temporalmente cors (seguridad para limitar qué webs pueden hacer peticiones) y tiene en mente añadir jsonwebtoken (JWT) y cookies en el futuro para gestionar usuarios e inicios de sesión.

Archivos adjuntos: El código tiene comentarios avisando que aún no soporta la subida de archivos (por ejemplo, folletos de la carrera o imágenes), pero planea integrarlo en el futuro antes de guardar los datos en DynamoDB.

🚀 Cómo ponerlo a correr en tu máquina
Si quieres probarlo localmente siguiendo los pasos del comando nvm que vimos antes:

Asegúrate de estar en la carpeta donde están estos archivos.

Ejecuta npm install para descargar Express y los módulos de AWS.

Paso crítico: Necesitas crear un archivo llamado .env en la raíz del proyecto con tus credenciales de AWS, de lo contrario fallará al conectarse:

Fragmento de código
AWS_ACCESS_KEY_ID=tu_clave_aqui
AWS_SECRET_ACCESS_KEY=tu_secreto_aqui
AWS_SESSION_TOKEN=tu_token_si_aplica
Ejecuta npm start para encender el servidor. Verás el mensaje Server listening on port 5000.

Para probarlo, puedes usar las mismas líneas de comandos curl que el desarrollador dejó escritas como ejemplo al final de su archivo server.js.


## Context pel Frontend

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
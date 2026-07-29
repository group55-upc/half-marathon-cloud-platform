# deploy.ps1
# Despliegue completo de la plataforma desde cero, en una sola pasada.
#
#   Infraestructura (Terraform) -> imagen Docker (ECR) -> servicio (ECS)
#   -> frontend (Angular + S3) -> datos de ejemplo (DynamoDB)
#
# Uso:
#   cd C:\Users\itzel.lorente\proyectos\half-marathon-cloud-platform
#   .\deploy.ps1
#
# Opciones:
#   .\deploy.ps1 -SkipSeed      No carga las carreras de ejemplo
#   .\deploy.ps1 -SkipFrontend  Solo despliega backend e infraestructura
#
# Requisitos: AWS CLI, Terraform, Docker Desktop arrancado, Node.js,
# y credenciales de AWS validas exportadas en esta sesion.

[CmdletBinding()]
param(
    [switch]$SkipSeed,
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# --- utilidades de salida ---------------------------------------------------

$script:paso = 0
function Write-Paso($texto) {
    $script:paso++
    Write-Host ""
    Write-Host "=== [$script:paso] $texto " -ForegroundColor Cyan -NoNewline
    Write-Host ("=" * [Math]::Max(0, 60 - $texto.Length)) -ForegroundColor Cyan
}
function Write-Ok($texto)     { Write-Host "    OK  $texto" -ForegroundColor Green }
function Write-Info($texto)   { Write-Host "    --  $texto" -ForegroundColor Gray }
function Write-Aviso($texto)  { Write-Host "    !   $texto" -ForegroundColor Yellow }

function Abortar($texto) {
    Write-Host ""
    Write-Host "ABORTADO: $texto" -ForegroundColor Red
    Write-Host ""
    exit 1
}

$inicio = Get-Date

# --- 1. comprobar herramientas ---------------------------------------------

Write-Paso "Comprobando herramientas"

foreach ($cmd in @("aws", "terraform", "docker", "npm")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Abortar "No encuentro '$cmd' en el PATH. Instalalo o abre una terminal nueva."
    }
    Write-Ok $cmd
}

# Docker tiene que estar arrancado, no solo instalado
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Abortar "Docker esta instalado pero no responde. Arranca Docker Desktop y espera a que ponga 'Engine running'."
}
Write-Ok "Docker Desktop respondiendo"

# --- 2. comprobar credenciales de AWS --------------------------------------

Write-Paso "Comprobando credenciales de AWS"

$identidad = aws sts get-caller-identity --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Abortar "Las credenciales no son validas o han caducado. Copialas de nuevo del laboratorio de Vocareum."
}
$cuenta = ($identidad | ConvertFrom-Json).Account
Write-Ok "Cuenta AWS $cuenta"

# --- 3. infraestructura base (sin ECS) -------------------------------------

Write-Paso "Creando infraestructura base (red, DynamoDB, ECR, S3, ALB)"
Write-Info "El cluster ECS se crea despues, cuando ya exista la imagen en ECR"

Push-Location (Join-Path $root "backend\infra")
try {
    terraform init -input=false | Out-Null
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'terraform init'." }
    Write-Ok "terraform init"

    terraform apply -auto-approve -input=false -var="enable-ECS=false"
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'terraform apply' de la fase base." }
    Write-Ok "Infraestructura base creada"

    $registryUrl = (terraform output -raw registry-url).Trim()
    $s3Url       = (terraform output -raw s3-url).Trim()
}
finally { Pop-Location }

$registryHost = $registryUrl.Split('/')[0]
$bucket       = $s3Url.Split('.')[0]
$imagen       = "${registryUrl}:v1.0"

Write-Info "ECR:    $registryUrl"
Write-Info "Bucket: $bucket"

# --- 4. construir y subir la imagen ----------------------------------------

Write-Paso "Construyendo la imagen Docker del backend"

Push-Location (Join-Path $root "backend\code")
try {
    docker build -t marathon-backend -f Dockerfile .
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'docker build'." }
    Write-Ok "Imagen construida"

    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $registryHost
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo el login contra ECR." }
    Write-Ok "Autenticado en ECR"

    docker tag marathon-backend:latest $imagen
    docker push $imagen
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'docker push'. Revisa que el repositorio ECR exista." }
    Write-Ok "Imagen subida como $imagen"
}
finally { Pop-Location }

# --- 5. desplegar el servicio ECS ------------------------------------------

Write-Paso "Desplegando el servicio en ECS Fargate"

Push-Location (Join-Path $root "backend\infra")
try {
    terraform apply -auto-approve -input=false -var="enable-ECS=true"
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'terraform apply' de la fase ECS." }
    Write-Ok "Cluster, task definition y service creados"

    $albUrl = (terraform output -raw alb-url).Trim()
}
finally { Pop-Location }

$api = "http://$albUrl"
Write-Info "ALB: $api"

# Por si el servicio ya existia de una ejecucion anterior, forzamos
# que recoja la imagen recien subida.
aws ecs update-service --cluster marathon-cluster --service marathon-service `
    --force-new-deployment --output json 2>&1 | Out-Null

# --- 6. esperar a que el backend responda ----------------------------------

Write-Paso "Esperando a que el backend este disponible"
Write-Info "Las tareas Fargate tardan 1-3 minutos en arrancar y pasar el health check"

$maxIntentos = 40   # 40 x 15s = 10 minutos
$vivo = $false

for ($i = 1; $i -le $maxIntentos; $i++) {
    try {
        $r = Invoke-WebRequest -Uri $api -UseBasicParsing -TimeoutSec 10
        if ($r.StatusCode -eq 200) { $vivo = $true; break }
    }
    catch { }
    Write-Host "    esperando... intento $i de $maxIntentos" -ForegroundColor DarkGray
    Start-Sleep -Seconds 15
}

if (-not $vivo) {
    Write-Aviso "El backend no responde todavia despues de 10 minutos."
    Write-Aviso "Revisa las tareas en la consola: ECS -> marathon-cluster -> marathon-service -> Tasks."
    Write-Aviso "Si ves 'CannotPullContainerError', la imagen no llego bien a ECR."
    Abortar "El backend no arranco. La infraestructura si esta creada, puedes investigar sin rehacerla."
}
Write-Ok "Backend respondiendo en $api"

# Comprobamos tambien la conexion con DynamoDB
try {
    Invoke-RestMethod -Uri "$api/connection" -TimeoutSec 10 | Out-Null
    Write-Ok "Backend conectado a DynamoDB"
}
catch {
    Write-Aviso "El backend responde pero no llega a DynamoDB. Revisa los VPC endpoints y el rol LabRole."
}

# --- 7. frontend -----------------------------------------------------------

if ($SkipFrontend) {
    Write-Paso "Frontend omitido (-SkipFrontend)"
}
else {
    Write-Paso "Compilando y publicando el frontend"

    # La URL del ALB cambia en cada despliegue, asi que la inyectamos aqui.
    # (Mientras la URL siga hardcodeada en el codigo: ver docs/mejoras-propuestas.md)
    $servicio = Join-Path $root "frontend\code\src\app\services\race.service.ts"
    $contenido = Get-Content $servicio -Raw
    $nuevo = $contenido -replace "private readonly apiUrl = '[^']*';", "private readonly apiUrl = '$api';"

    if ($nuevo -eq $contenido) {
        Write-Aviso "No he podido localizar la linea de apiUrl en race.service.ts. Revisala a mano."
    }
    else {
        Set-Content -Path $servicio -Value $nuevo -NoNewline
        Write-Ok "race.service.ts apuntando a $api"
    }

    Push-Location (Join-Path $root "frontend\code")
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Info "Instalando dependencias de Angular (puede tardar unos minutos)"
            npm install --silent
            if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'npm install' del frontend." }
            Write-Ok "Dependencias instaladas"
        }
        else { Write-Ok "Dependencias ya presentes" }

        npm run build
        if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'npm run build'." }
        Write-Ok "Frontend compilado"

        aws s3 sync "dist\Frontend\browser" "s3://$bucket" --delete --only-show-errors
        if ($LASTEXITCODE -ne 0) { Abortar "Fallo la subida a S3." }
        Write-Ok "Frontend publicado en el bucket $bucket"
    }
    finally { Pop-Location }
}

# --- 8. datos de ejemplo ---------------------------------------------------

if ($SkipSeed) {
    Write-Paso "Carga de datos omitida (-SkipSeed)"
}
else {
    Write-Paso "Cargando carreras de ejemplo"
    $seed = Join-Path $root "database\seed-races.ps1"
    if (Test-Path $seed) {
        & $seed -ApiUrl $api
    }
    else {
        Write-Aviso "No encuentro database\seed-races.ps1, me lo salto."
    }
}

# --- resumen ---------------------------------------------------------------

$duracion = (Get-Date) - $inicio

Write-Host ""
Write-Host ("=" * 68) -ForegroundColor Green
Write-Host " DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host ("=" * 68) -ForegroundColor Green
Write-Host ""
Write-Host "  Web        http://$s3Url" -ForegroundColor White
Write-Host "  API        $api" -ForegroundColor White
Write-Host "  Registro   $registryUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "  Tiempo total: $([Math]::Round($duracion.TotalMinutes, 1)) minutos" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANTE: abre la web con http://, no https." -ForegroundColor Yellow
Write-Host "  Los endpoints de web estatica de S3 no soportan HTTPS." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Para no consumir credito cuando acabes:" -ForegroundColor Yellow
Write-Host "    cd backend\infra ; terraform destroy" -ForegroundColor Yellow
Write-Host ""

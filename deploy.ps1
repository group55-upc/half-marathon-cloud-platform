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
# y credenciales de AWS validas (en ~/.aws/credentials o como variables).
#
# NOTA: no se usa $ErrorActionPreference = "Stop" a proposito. Docker,
# terraform, npm y aws escriben avisos inofensivos por el canal de error,
# y con "Stop" PowerShell los interpreta como fallos y aborta. En su lugar
# se comprueba el codigo de salida ($LASTEXITCODE) despues de cada comando.

[CmdletBinding()]
param(
    [switch]$SkipSeed,
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

# --- utilidades de salida ---------------------------------------------------

$script:paso = 0
function Write-Paso($texto) {
    $script:paso++
    Write-Host ""
    Write-Host "=== [$script:paso] $texto " -ForegroundColor Cyan -NoNewline
    Write-Host ("=" * [Math]::Max(0, 58 - $texto.Length)) -ForegroundColor Cyan
}
function Write-Ok($texto)    { Write-Host "    OK  $texto" -ForegroundColor Green }
function Write-Info($texto)  { Write-Host "    --  $texto" -ForegroundColor Gray }
function Write-Aviso($texto) { Write-Host "    !   $texto" -ForegroundColor Yellow }

function Abortar($texto) {
    Write-Host ""
    Write-Host "ABORTADO: $texto" -ForegroundColor Red
    Write-Host "Nada de lo ya creado se ha destruido: puedes corregir y reintentar." -ForegroundColor Gray
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

# Docker tiene que estar arrancado, no solo instalado.
# '*> $null' descarta TODOS los canales de salida, incluidos los avisos.
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Abortar "Docker esta instalado pero no responde. Arranca Docker Desktop y espera a que ponga 'Engine running'."
}
Write-Ok "Docker Desktop respondiendo"

# --- 2. comprobar credenciales de AWS --------------------------------------

Write-Paso "Comprobando credenciales de AWS"

$identidad = aws sts get-caller-identity --output json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $identidad) {
    Abortar "Las credenciales no son validas o han caducado. Arranca el laboratorio y copialas de nuevo."
}
try   { $cuenta = ($identidad | ConvertFrom-Json).Account }
catch { $cuenta = "(desconocida)" }
Write-Ok "Cuenta AWS $cuenta"

# --- 3. infraestructura base (sin ECS) -------------------------------------

Write-Paso "Creando infraestructura base (red, DynamoDB, ECR, S3, ALB)"
Write-Info "El cluster ECS se crea despues, cuando ya exista la imagen en ECR"

Push-Location (Join-Path $root "backend\infra")
try {
    $logInit = terraform init -input=false 2>&1
    if ($LASTEXITCODE -ne 0) {
        $logInit | ForEach-Object { Write-Host $_ }
        Abortar "Fallo 'terraform init'."
    }
    Write-Ok "terraform init"

    terraform apply -auto-approve -input=false -var="enable-ECS=false"
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'terraform apply' de la fase base." }
    Write-Ok "Infraestructura base creada"

    $registryUrl = (terraform output -raw registry-url 2>$null)
    $s3Url       = (terraform output -raw s3-url 2>$null)
}
finally { Pop-Location }

if (-not $registryUrl -or -not $s3Url) {
    Abortar "No he podido leer los outputs de Terraform (registry-url / s3-url)."
}

$registryUrl  = $registryUrl.Trim()
$s3Url        = $s3Url.Trim()
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

    # Login contra ECR.
    #
    # OJO: NO usar la tuberia de PowerShell aqui:
    #   aws ecr get-login-password | docker login --password-stdin ...
    # PowerShell termina cada linea con \r\n. Docker quita el \n pero deja
    # el \r pegado al final del token, ECR recibe una cabecera malformada
    # y responde "400 Bad Request".
    #
    # Solucion: pasar el token como argumento, limpiando espacios en blanco.
    $token = (aws ecr get-login-password --region us-east-1 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
        Abortar "No he podido obtener el token de ECR. Revisa las credenciales del laboratorio."
    }

    docker login --username AWS --password $token $registryHost
    if ($LASTEXITCODE -ne 0) {
        # Plan B: dejar que cmd.exe haga la tuberia, que pasa los bytes
        # tal cual sin anadir saltos de linea.
        Write-Aviso "El login directo ha fallado, probando con cmd.exe"
        cmd /c "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $registryHost"
        if ($LASTEXITCODE -ne 0) { Abortar "Fallo el login contra ECR por las dos vias." }
    }
    Write-Ok "Autenticado en ECR"

    docker tag marathon-backend:latest $imagen
    if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'docker tag'." }

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

    $albUrl = (terraform output -raw alb-url 2>$null)
}
finally { Pop-Location }

if (-not $albUrl) { Abortar "No he podido leer el output 'alb-url' de Terraform." }

$albUrl = $albUrl.Trim()
$api    = "http://$albUrl"
Write-Info "ALB: $api"

# Por si el servicio ya existia de una ejecucion anterior, forzamos que
# recoja la imagen recien subida. Si acaba de crearse, esto es inocuo.
aws ecs update-service --cluster marathon-cluster --service marathon-service `
    --force-new-deployment *> $null

# --- 6. esperar a que el backend responda ----------------------------------

Write-Paso "Esperando a que el backend este disponible"
Write-Info "Las tareas Fargate tardan 1-3 minutos en arrancar y pasar el health check"

$maxIntentos = 40   # 40 x 15s = 10 minutos
$vivo = $false

for ($i = 1; $i -le $maxIntentos; $i++) {
    try {
        $r = Invoke-WebRequest -Uri $api -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $vivo = $true; break }
    }
    catch { }
    Write-Host "    esperando... intento $i de $maxIntentos" -ForegroundColor DarkGray
    Start-Sleep -Seconds 15
}

if (-not $vivo) {
    Write-Aviso "El backend no responde despues de 10 minutos."
    Write-Aviso "Mira las tareas en la consola: ECS -> marathon-cluster -> marathon-service -> Tasks."
    Write-Aviso "Si ves 'CannotPullContainerError', la imagen no llego bien a ECR."
    Abortar "El backend no arranco. La infraestructura si esta creada."
}
Write-Ok "Backend respondiendo en $api"

# Comprobamos tambien la conexion con DynamoDB
try {
    Invoke-RestMethod -Uri "$api/connection" -TimeoutSec 10 -ErrorAction Stop | Out-Null
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
    # (Mientras siga hardcodeada: ver docs/mejoras-propuestas.md, punto 2)
    $servicio  = Join-Path $root "frontend\code\src\app\services\race.service.ts"
    $contenido = Get-Content $servicio -Raw
    $nuevo     = $contenido -replace "private readonly apiUrl = '[^']*';", "private readonly apiUrl = '$api';"

    if ($nuevo -eq $contenido) {
        Write-Aviso "No he localizado la linea de apiUrl en race.service.ts. Revisala a mano."
    }
    else {
        Set-Content -Path $servicio -Value $nuevo -NoNewline
        Write-Ok "race.service.ts apuntando a $api"
    }

    Push-Location (Join-Path $root "frontend\code")
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Info "Instalando dependencias de Angular (unos minutos)"
            npm install
            if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'npm install' del frontend." }
            Write-Ok "Dependencias instaladas"
        }
        else { Write-Ok "Dependencias ya presentes" }

        npm run build
        if ($LASTEXITCODE -ne 0) { Abortar "Fallo 'npm run build'." }
        Write-Ok "Frontend compilado"

        $salida = Join-Path (Get-Location) "dist\Frontend\browser"
        if (-not (Test-Path $salida)) { Abortar "No encuentro la carpeta compilada: $salida" }

        # Comprobacion del arreglo 1: no debe haber codigo fuente en la salida
        $fuentes = Get-ChildItem -Path $salida -Recurse -Filter *.ts -ErrorAction SilentlyContinue
        if ($fuentes) {
            Write-Aviso "La compilacion contiene $($fuentes.Count) archivos .ts. Revisa el bloque 'assets' de angular.json."
        }
        else {
            Write-Ok "La compilacion no contiene codigo fuente"
        }

        aws s3 sync $salida "s3://$bucket" --delete --only-show-errors
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
    if (Test-Path $seed) { & $seed -ApiUrl $api }
    else { Write-Aviso "No encuentro database\seed-races.ps1, me lo salto." }
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

# seed-races.ps1
# Carga carreras de ejemplo en la API del backend (DynamoDB tabla "races").
#
# Uso:
#   cd C:\Users\itzel.lorente\proyectos\half-marathon-cloud-platform\database
#   .\seed-races.ps1
#
# Si tu ALB cambia de nombre (tras un terraform destroy/apply), pasa la URL nueva:
#   .\seed-races.ps1 -ApiUrl "http://lb-backend-XXXXXXX.us-east-1.elb.amazonaws.com"
#
# NOTA: las fechas son aproximadas / de ejemplo. Ajustalas si necesitas datos reales.

param(
    [string]$ApiUrl = "http://lb-backend-1129452724.us-east-1.elb.amazonaws.com"
)

$endpoint = "$ApiUrl/races"

$carreras = @(
    @{ name = "Mitja Marato de Barcelona"; city = "Barcelona";  country = "Spain";          date = "2027-02-14"; web = "https://www.edreamsmitjabarcelona.com"; distance = 21.0975; routeKey = "routes/barcelona-half-marathon.geojson" },
    @{ name = "Medio Maraton de Madrid";   city = "Madrid";     country = "Spain";          date = "2027-04-04"; web = "https://www.mediomaratonmadrid.es";      distance = 21.0975; routeKey = "routes/madrid-half-marathon.geojson" },
    @{ name = "Medio Maraton de Valencia"; city = "Valencia";   country = "Spain";          date = "2027-10-24"; web = "https://mediomaratonvalencia.com";       distance = 21.0975; routeKey = "routes/valencia-half-marathon.geojson" },
    @{ name = "Lisbon Half Marathon";      city = "Lisbon";     country = "Portugal";       date = "2027-03-14"; web = "https://maratonaclubedeportugal.com";       distance = 21.0975; routeKey = "routes/lisbon-half-marathon.geojson" },
    @{ name = "Berlin Half Marathon";      city = "Berlin";     country = "Germany";        date = "2027-04-04"; web = "https://www.generali-berliner-halbmarathon.de/en"; distance = 21.0975; routeKey = "routes/berlin-half-marathon.geojson" },
    @{ name = "Paris Half Marathon";       city = "Paris";      country = "France";         date = "2027-03-07"; web = "https://www.semideparis.com";           distance = 21.0975 },
    @{ name = "Roma-Ostia Half Marathon";  city = "Rome";       country = "Italy";          date = "2027-02-28"; web = "https://romaostia.it/";                  distance = 21.0975; routeKey = "routes/roma-ostia-half-marathon.geojson" },
    @{ name = "Great North Run";           city = "Newcastle";  country = "United Kingdom"; date = "2027-09-12"; web = "https://www.greatrun.org";              distance = 21.0975; routeKey = "routes/great-north-run.geojson" },
    @{ name = "Copenhagen Half Marathon";  city = "Copenhagen"; country = "Denmark";        date = "2027-09-19"; web = "https://cphhalf.dk";                    distance = 21.0975; routeKey = "routes/copenhagen-half-marathon.geojson"},
    @{ name = "United NYC Half";           city = "New York";   country = "United States";  date = "2027-03-21"; web = "https://www.nyrr.org";                  distance = 21.0975; routeKey = "routes/nyc-half-marathon.geojson" },
    @{ name = "Zurich Marato Barcelona";   city = "Barcelona";  country = "Spain";          date = "2027-03-14"; web = "https://www.zurichmaratobarcelona.es";   distance = 42.195 },
    @{ name = "Berlin Marathon";           city = "Berlin";     country = "Germany";        date = "2027-09-26"; web = "https://www.bmw-berlin-marathon.com";    distance = 42.195 }
)

Write-Host "Enviando $($carreras.Count) carreras a $endpoint" -ForegroundColor Cyan
Write-Host ""

$ok = 0
$fallos = 0

foreach ($carrera in $carreras) {
    $json = $carrera | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri $endpoint -Method Post -ContentType "application/json" -Body $json | Out-Null
        Write-Host "  OK   $($carrera.name)" -ForegroundColor Green
        $ok++
    }
    catch {
        Write-Host "  FALLO $($carrera.name) -> $($_.Exception.Message)" -ForegroundColor Red
        $fallos++
    }
}

Write-Host ""
Write-Host "Resultado: $ok creadas, $fallos fallidas" -ForegroundColor Cyan

# Comprobacion: cuantas carreras hay ahora en total
try {
    $todas = Invoke-RestMethod -Uri $endpoint -Method Get
    Write-Host "Total de carreras en la base de datos: $($todas.Count)" -ForegroundColor Cyan
}
catch {
    Write-Host "No se pudo leer el total: $($_.Exception.Message)" -ForegroundColor Yellow
}

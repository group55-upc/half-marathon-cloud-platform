# Race Route Maps Feature

## 1. Overview

This document describes the complete implementation, validation, deployment, and Git workflow followed to add race route visualization to the **Half Marathon Cloud Platform**.

The objective of the feature was to allow users to visualize selected race courses directly from the frontend while keeping the route files stored securely in AWS.

The implementation was developed in the branch:

```text
feature/race-route-maps
```

The feature was validated in AWS before being proposed for merge into `main`.

---

## 2. Final Result

The platform now supports route visualization for the following races:

- Barcelona Half Marathon
- Madrid Half Marathon
- Valencia Half Marathon
- Lisbon Half Marathon
- Berlin Half Marathon
- Roma-Ostia Half Marathon
- Great North Run
- Copenhagen Half Marathon
- United NYC Half

The following races remain in the platform without route visualization:

- Paris Half Marathon
- Zurich Marato Barcelona
- Berlin Marathon

The frontend automatically displays **View Route** only when a race contains a valid `routeKey`.

---

## 3. Technology Stack

### Frontend

- Angular
- TypeScript
- HTML
- CSS
- Leaflet
- OpenStreetMap

### Backend

- Node.js
- Express
- JavaScript
- AWS SDK for JavaScript

### Infrastructure

- Terraform
- HCL
- Amazon ECS Fargate
- Amazon ECR
- Application Load Balancer
- Amazon S3
- Amazon DynamoDB
- Amazon VPC
- CloudWatch
- SNS

### Supporting tools

- Docker
- AWS CLI
- PowerShell
- Bash
- Python
- Git / GitHub

---

## 4. Architecture

The implemented route flow is:

```text
                         USER
                           |
                           v
                 Angular Frontend
                 hosted in Amazon S3
                           |
                           | GET /races/:id/route
                           v
               Application Load Balancer
                           |
                           v
                  ECS Fargate Backend
                    Node.js / Express
                      /           \
                     /             \
                    v               v
              DynamoDB          Private S3
              race data         route files
              routeKey          *.geojson
```

The important design decision is that the race record in DynamoDB stores a logical S3 object key:

```text
routeKey = "routes/example-race.geojson"
```

The frontend never reads the private routes bucket directly.

Instead:

1. The frontend requests the route from the backend.
2. The backend reads the race from DynamoDB.
3. The backend obtains the `routeKey`.
4. The backend retrieves the GeoJSON object from S3.
5. The backend returns the GeoJSON to the frontend.
6. Leaflet renders the route using OpenStreetMap tiles.

---

## 5. Backend Implementation

### 5.1 S3 SDK support

The backend was extended with the AWS S3 client:

```javascript
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
```

The package dependency was added to the backend package configuration.

### 5.2 Route key support in race creation

Race creation was modified so that `routeKey` is stored only when supplied:

```javascript
...(req.body.routeKey ? { routeKey: req.body.routeKey } : {})
```

This allows races without a map to continue working normally.

### 5.3 Route retrieval endpoint

A new backend endpoint was added:

```text
GET /races/:id/route
```

The endpoint:

1. Retrieves the race from DynamoDB.
2. Verifies that the race exists.
3. Verifies that it has a `routeKey`.
4. Reads the route file from the private S3 bucket.
5. Returns it as GeoJSON.

Simplified implementation:

```javascript
app.get("/races/:id/route", async (req, res) => {
  try {
    const { Item } = await dbClient.send(new GetCommand({
      TableName: "races",
      Key: { id: req.params.id }
    }));

    if (!Item) {
      return res.status(404).json({ error: "race not found" });
    }

    if (!Item.routeKey) {
      return res.status(404).json({ error: "route not available" });
    }

    const bucketName = process.env.ROUTES_BUCKET;

    if (!bucketName) {
      return res.status(500).json({ error: "routes bucket not configured" });
    }

    const routeObject = await s3Client.send(new GetObjectCommand({
      Bucket: bucketName,
      Key: Item.routeKey
    }));

    const routeGeoJson = await routeObject.Body.transformToString();

    res.status(200)
      .type("application/geo+json")
      .send(routeGeoJson);

  } catch (error) {
    console.error("Error retrieving race route:", error);
    res.status(500).json({ error: "route retrieval error" });
  }
});
```

---

## 6. Frontend Implementation

### 6.1 Race model

The frontend race interface was extended with:

```typescript
routeKey?: string;
```

### 6.2 Race service

The frontend service includes a method equivalent to:

```typescript
getRaceRoute(id: string)
```

which calls:

```text
GET /races/:id/route
```

### 6.3 Runtime backend URL configuration

A runtime configuration file was introduced:

```text
frontend/code/src/config.js
```

Development version:

```javascript
window.__APP_CONFIG__ = {
  apiUrl: 'http://localhost:5000'
};
```

Angular loads it from `index.html`.

The frontend service obtains the API URL with:

```typescript
private readonly apiUrl =
  (window as AppWindow).__APP_CONFIG__?.apiUrl ??
  'http://localhost:5000';
```

This avoids hardcoding a specific ALB address in the Angular source code.

During deployment, `config.js` is regenerated with the current ALB hostname.

---

## 7. Race Route Page

A dedicated Angular route page was implemented and lazy-loaded.

Example route:

```text
/race/:id/route
```

The page includes:

- race title
- race city and country
- official distance
- event link
- Leaflet map
- route polyline
- START marker
- FINISH marker

---

## 8. Leaflet and OpenStreetMap

Leaflet is used for visualization and OpenStreetMap provides the basemap.

Example map initialization:

```typescript
this.map = L.map('race-map', {
  zoomControl: true
});

L.tileLayer(
  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors'
  }
).addTo(this.map);
```

The race route is drawn from the GeoJSON:

```typescript
const routeLayer = L.geoJSON(
  this.routeData as any,
  {
    style: () => ({
      color: '#2563eb',
      weight: 5,
      opacity: 0.95
    })
  }
).addTo(this.map);
```

The map automatically fits the route:

```typescript
const bounds = routeLayer.getBounds();

if (bounds.isValid()) {
  this.map.fitBounds(
    bounds,
    { padding: [30, 30] }
  );
}
```

---

## 9. START and FINISH Markers

The START and FINISH locations are automatically calculated from the first and last points of the route `LineString`.

The order used during map initialization was important:

```text
1. Create map
2. Add tile layer
3. Add GeoJSON route
4. fitBounds()
5. Add START and FINISH markers
```

Adding the markers before `fitBounds()` caused a Leaflet rendering error during development.

The final markers are rendered as green START and red FINISH markers.

---

## 10. Dashboard Logic

The dashboard was designed to remain generic.

The `View Route` button appears only when both conditions are true:

```typescript
race.routeKey && race.id
```

Conceptually:

```html
@if (race.routeKey && race.id) {
  <a [routerLink]="['/race', race.id, 'route']">
    View Route
  </a>
}
```

This means that no per-race frontend logic is required.

Adding a new route only requires:

1. adding a GeoJSON file
2. adding the correct `routeKey` to the race record

---

## 11. Route File Strategy

All route files are stored under:

```text
database/routes/
```

GeoJSON files use the following structure:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Race Name",
        "source": "Route source",
        "status": "reference"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [0.0, 0.0]
        ]
      }
    }
  ]
}
```

Coordinates are stored as:

```text
[longitude, latitude]
```

Routes are deliberately marked as:

```text
status: reference
```

because a published GPX/KML/polyline may not reproduce the certified measurement line with survey-level precision.

---

## 12. Route Acquisition and Validation Method

Every route was reviewed individually.

The general process was:

```text
Official or reliable source
        |
        v
GPX / KML / official map data
        |
        v
Parse coordinates
        |
        v
Calculate Haversine distance
        |
        v
Check largest consecutive segments
        |
        v
Compare with official race distance
        |
        v
Convert to GeoJSON
        |
        v
Validate JSON
        |
        v
Add routeKey
```

For half marathons the comparison distance was:

```text
21.0975 km
```

The distance comparison was used as a validation mechanism, not as proof that the digital polyline is the certified measurement line.

---

## 13. Race Route Sources and Results

### 13.1 Barcelona Half Marathon

Files:

```text
barcelona-half-marathon.gpx
barcelona-half-marathon.geojson
```

Validation:

- 334 points
- approximately 21.346 km
- reference route based on an event-published GPX

Route key:

```text
routes/barcelona-half-marathon.geojson
```

### 13.2 Madrid Half Marathon

Files:

```text
madrid-half-marathon.gpx
madrid-half-marathon.geojson
```

Validation:

- 381 points
- approximately 21.446 km
- event-published reference GPX

Route key:

```text
routes/madrid-half-marathon.geojson
```

### 13.3 Valencia Half Marathon

Files:

```text
valencia-half-marathon.gpx
valencia-half-marathon.geojson
```

Validation:

- 440 points
- approximately 21.365 km
- route published by Valencia Ciudad del Running via Strava
- no anomalous route jumps found

Route key:

```text
routes/valencia-half-marathon.geojson
```

### 13.4 Lisbon Half Marathon

The official event provided a Google My Maps course.

The route was exported as KML.

Files:

```text
lisbon-half-marathon.kml
lisbon-half-marathon.geojson
```

The relevant KML layer was:

```text
M.M. Lisboa ponte 2026 final
```

Validation:

- 225 points
- approximately 21.212 km
- official event KML

Route key:

```text
routes/lisbon-half-marathon.geojson
```

### 13.5 Berlin Half Marathon

The official interactive map was exported as KML.

Files:

```text
berlin-half-marathon.kml
berlin-half-marathon.geojson
```

The main route layer was:

```text
Strecke_V7.2 = 21,1 km
```

Validation:

- 258 points
- approximately 21.090 km
- difference from official half marathon distance: approximately 8 m

Route key:

```text
routes/berlin-half-marathon.geojson
```

### 13.6 Roma-Ostia Half Marathon

Files:

```text
roma-ostia-half-marathon.gpx
roma-ostia-half-marathon.geojson
```

Validation:

- 372 points
- approximately 21.070 km
- difference from official half marathon distance: approximately 28 m
- validated visually against the published official course

Route key:

```text
routes/roma-ostia-half-marathon.geojson
```

### 13.7 Great North Run

Files:

```text
great-north-run.gpx
great-north-run.geojson
```

Validation:

- 382 points
- approximately 21.159 km
- approximately +62 m compared with official distance
- no anomalous jumps

Route key:

```text
routes/great-north-run.geojson
```

### 13.8 Copenhagen Half Marathon

The official CPH Half interactive map did not expose a GPX download.

The route geometry was therefore extracted directly from the JSON response used by the official map.

The browser developer tools showed:

```text
data:
  pins: 129
  route: 410
  map_drawings: 55
```

The route used coordinate pairs in the following format:

```text
[longitude, latitude]
```

Example:

```text
["12.567721", "55.707257"]
```

The raw route contained:

- 410 points
- 69 consecutive duplicate points

After removing consecutive duplicates:

- 341 points remained
- route length approximately 21.390 km

The route came directly from the official CPH Half interactive map.

File:

```text
copenhagen-half-marathon.geojson
```

Route key:

```text
routes/copenhagen-half-marathon.geojson
```

### 13.9 United NYC Half

Files:

```text
nyc-half-marathon.gpx
nyc-half-marathon.geojson
```

Validation:

- 573 points
- approximately 21.344 km
- reference track validated against the published race course

Route key:

```text
routes/nyc-half-marathon.geojson
```

---

## 14. Races Without Route Visualization

Three races were intentionally kept without a route.

### Paris Half Marathon

Only the official PDF course map was available during implementation.

Rather than manually digitizing the route and introducing unnecessary uncertainty, the race was kept without a `routeKey`.

### Zurich Marato Barcelona

Full marathon route visualization was not required for the final feature scope.

### Berlin Marathon

Full marathon route visualization was not required for the final feature scope.

The application handles this automatically because races without `routeKey` do not display `View Route`.

---

## 15. DynamoDB Seed Data

The PowerShell seed file was updated:

```text
database/seed-races.ps1
```

Example:

```powershell
@{
  name = "Great North Run"
  city = "Newcastle"
  country = "United Kingdom"
  date = "2027-09-12"
  web = "https://www.greatrun.org"
  distance = 21.0975
  routeKey = "routes/great-north-run.geojson"
}
```

The seed was executed against the deployed API:

```bash
pwsh ./database/seed-races.ps1 -ApiUrl "$API_URL"
```

Result:

```text
12 created
0 failed
Total races in database: 12
```

---

## 16. Terraform S3 Route Automation

A private S3 bucket was added for race routes.

Terraform automatically detects every `.geojson` file in:

```text
database/routes/
```

using:

```hcl
locals {
  race_route_files = fileset(
    "${path.module}/../database/routes",
    "*.geojson"
  )
}
```

The bucket uses:

```hcl
resource "aws_s3_bucket" "race-routes" {
  bucket_prefix = "marathon-routes-"
  force_destroy = true

  tags = local.tags
}
```

Public access is blocked.

Each GeoJSON file is uploaded automatically:

```hcl
resource "aws_s3_object" "race-routes" {
  for_each = local.race_route_files

  bucket = aws_s3_bucket.race-routes.id
  key    = "routes/${each.value}"

  source = "${path.module}/../database/routes/${each.value}"
  etag   = filemd5("${path.module}/../database/routes/${each.value}")

  content_type = "application/geo+json"
}
```

This means that adding another `.geojson` file does not require creating another Terraform resource manually.

---

## 17. ECS Configuration

The ECS backend receives the routes bucket through an environment variable:

```text
ROUTES_BUCKET
```

Terraform provides the actual bucket ID:

```hcl
environment = [
  {
    name  = "ROUTES_BUCKET"
    value = aws_s3_bucket.race-routes.id
  }
]
```

---

## 18. Deployment Process

The AWS environment had previously been destroyed, so the complete environment was recreated.

### 18.1 AWS credentials

Temporary AWS credentials were loaded into the shell.

Example:

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
export AWS_REGION="us-east-1"
```

Credential validation:

```bash
aws sts get-caller-identity
```

AWS account used during validation:

```text
229199215188
```

---

## 19. Terraform Phase 1

Terraform was initialized:

```bash
terraform -chdir=infrastructure init
```

Validation:

```bash
terraform -chdir=infrastructure validate
```

Initial deployment was planned with ECS disabled:

```bash
terraform -chdir=infrastructure plan \
  -var='enable-ECS=false'
```

This phase creates the base infrastructure before the backend Docker image exists in ECR.

---

## 20. AWS Academy SCP Issue

During Terraform deployment, AWS returned:

```text
AccessDenied:
s3:GetBucketObjectLockConfiguration
```

The request was explicitly denied by a Service Control Policy in the AWS lab organization.

This was not an application error.

The AWS Terraform provider attempted to read S3 Object Lock configuration during resource refresh, but the training environment SCP prohibited that API operation.

---

## 21. Partial Apply Recovery

The initial Terraform apply created many resources before failing.

The state was inspected:

```bash
terraform -chdir=infrastructure state list
```

S3 buckets were confirmed with:

```bash
aws s3 ls
```

Both buckets existed:

```text
marathon-cloudupc-website
marathon-routes-...
```

A no-refresh plan was then used:

```bash
terraform -chdir=infrastructure plan \
  -refresh=false \
  -var='enable-ECS=false'
```

Terraform initially proposed replacing both S3 buckets.

Inspection showed:

```text
replace_because_tainted
```

for:

```text
aws_s3_bucket.race-routes
aws_s3_bucket.s3-website
```

The resources were safely untainted:

```bash
terraform -chdir=infrastructure untaint \
  aws_s3_bucket.race-routes

terraform -chdir=infrastructure untaint \
  aws_s3_bucket.s3-website
```

The new plan showed:

```text
0 to destroy
```

and deployment continued with:

```bash
terraform -chdir=infrastructure apply \
  -refresh=false \
  -var='enable-ECS=false'
```

---

## 22. Verification of Route Uploads

The routes bucket was verified directly:

```bash
aws s3 ls \
  s3://<routes-bucket>/routes/
```

All nine GeoJSON files were present.

---

## 23. Backend Docker Build and ECR Push

The backend image was built:

```bash
docker build \
  -t marathon-backend:v1.0 \
  ./backend/code
```

ECR repository URL:

```bash
ECR_URL=$(terraform -chdir=infrastructure output -raw registry-url)
ECR_REGISTRY=${ECR_URL%%/*}
```

Docker authenticated to ECR:

```bash
aws ecr get-login-password \
  --region us-east-1 \
  | docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"
```

Image tagging:

```bash
docker tag \
  marathon-backend:v1.0 \
  "$ECR_URL:v1.0"
```

Image upload:

```bash
docker push "$ECR_URL:v1.0"
```

---

## 24. Terraform Phase 2

After the backend image was available in ECR, ECS was enabled.

Because of the AWS Academy S3 SCP limitation, Terraform continued using:

```bash
terraform -chdir=infrastructure plan \
  -refresh=false
```

and:

```bash
terraform -chdir=infrastructure apply \
  -refresh=false
```

The deployment completed successfully.

---

## 25. Backend Health Validation

The deployed ALB hostname was obtained with:

```bash
terraform -chdir=infrastructure output -raw alb-url
```

The API variable was created:

```bash
API_URL="http://$(terraform -chdir=infrastructure output -raw alb-url)"
```

Initial requests returned HTTP 503 because ECS targets had not yet become healthy.

ECS was inspected with:

```bash
aws ecs list-clusters
aws ecs list-services --cluster marathon-cluster
aws ecs list-tasks --cluster marathon-cluster
```

The service showed:

```text
desired: 2
running: 2
pending: 0
steady state
```

Target group health was checked with:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

Both targets became:

```text
State: healthy
Port: 5000
```

The API then returned:

```text
HTTP/1.1 200 OK
```

for:

```bash
curl -i "$API_URL/"
curl -i "$API_URL/connection"
```

with:

```json
{"status":"ok"}
```

---

## 26. Frontend Build and Deployment

The frontend was built:

```bash
cd frontend/code
npm run build
```

The build completed successfully.

Two non-blocking warnings were observed:

- dashboard CSS exceeded the Angular configured budget
- Leaflet was detected as a CommonJS dependency

Neither prevented the application from building or running.

---

## 27. Runtime API URL Injection

After every Angular build, the generated `config.js` must contain the deployed ALB URL.

The correct URL was injected with:

```bash
API_URL="http://$(terraform -chdir=../../infrastructure output -raw alb-url)"

printf "window.__APP_CONFIG__ = {\n  apiUrl: '%s'\n};\n" \
  "$API_URL" \
  > dist/Frontend/browser/config.js
```

Validation:

```bash
cat dist/Frontend/browser/config.js
```

Example:

```javascript
window.__APP_CONFIG__ = {
  apiUrl: 'http://alb-backend-xxxxxxxx.us-east-1.elb.amazonaws.com'
};
```

---

## 28. Frontend Upload to S3

The Angular build was uploaded using:

```bash
aws s3 sync \
  dist/Frontend/browser \
  s3://marathon-cloudupc-website \
  --delete
```

The S3 website endpoint was then used to access the application.

---

## 29. Functional Validation

The complete application was tested.

### Dashboard

Confirmed:

- 12 races displayed
- `View Route` visible for the nine supported routes
- no `View Route` for Paris Half Marathon
- no `View Route` for Zurich Marato Barcelona
- no `View Route` for Berlin Marathon
- backend status displayed as `Service Online`

### Route pages

Every implemented route was opened and visually validated.

Confirmed:

- map loaded
- route line rendered correctly
- START marker visible
- FINISH marker visible
- race information displayed
- event link available
- backend remained online

All nine implemented maps were successfully validated.

---

## 30. S3 Static Website Limitation

The frontend is hosted using the Amazon S3 static website feature.

Angular client-side navigation works normally from the dashboard.

However, a direct browser refresh on a deep Angular URL such as:

```text
/race/<id>/route
```

may return an S3 `404`, because S3 static hosting does not natively understand Angular client-side routes.

This does not affect navigation through the application.

A future improvement could use CloudFront or an appropriate SPA fallback/error-document configuration.

---

## 31. Deployment Script Improvements

The deployment script was updated to:

- use the correct `infrastructure` directory
- avoid stale references to `backend/infra`
- build the Angular frontend
- inject the runtime API URL
- upload the frontend to S3

This prevents the deployed frontend from accidentally using:

```text
http://localhost:5000
```

after a production build.

---

## 32. Amplify

AWS Amplify exists in the Terraform configuration but was made optional.

Current configuration:

```text
enable-amplify = false
```

The current frontend deployment therefore uses:

```text
Angular build
   |
   v
Amazon S3 Static Website
```

instead of Amplify hosting.

This keeps the infrastructure explicit and easier to understand for the academic project.

---

## 33. Git Workflow

Development was performed on:

```text
feature/race-route-maps
```

Main implementation commits included:

```text
Make Amplify optional for local deployment
Add race route visualization functionality
Fix scroll restoration for route navigation
Add runtime API configuration for frontend
Update deployment script for runtime API config
Add Barcelona half marathon reference route
Fix GPX file permissions
Add start and finish markers to race route map
Improve race route map visualization
Refine race route styling and marker labels
Automatically upload race route GeoJSON files
Add race route maps for supported events
```

After final validation:

```bash
git status
```

returned:

```text
nothing to commit, working tree clean
```

---

## 34. Remote Branch and Pull Request

The branch was pushed to:

```text
origin/feature/race-route-maps
```

with:

```bash
git push -u origin feature/race-route-maps
```

A GitHub Pull Request was created from:

```text
feature/race-route-maps
```

into:

```text
main
```

At the time of final preparation:

- 12 commits were included
- all automated checks passed
- no merge conflicts existed
- the Pull Request was ready for team review
- `main` had not yet been modified

The merge was intentionally left pending until validation by the other team members.

---

## 35. Current Project State

The route map feature is complete and tested.

### Completed

- private S3 route storage
- Terraform automatic route upload
- DynamoDB route references
- backend S3 retrieval
- route API endpoint
- Angular route page
- Leaflet visualization
- OpenStreetMap integration
- START / FINISH markers
- generic dashboard button logic
- runtime backend configuration
- deployment in AWS
- route validation
- Git branch
- Pull Request

### Supported maps

```text
Barcelona Half Marathon
Madrid Half Marathon
Valencia Half Marathon
Lisbon Half Marathon
Berlin Half Marathon
Roma-Ostia Half Marathon
Great North Run
Copenhagen Half Marathon
United NYC Half
```

### Races intentionally without map

```text
Paris Half Marathon
Zurich Marato Barcelona
Berlin Marathon
```

---

## 36. Adding a New Race Route in the Future

The architecture is designed so that adding another route is straightforward.

### Step 1

Obtain a reliable GPX, KML, GeoJSON, or official map geometry.

### Step 2

Validate the route:

- coordinate count
- route distance
- START / FINISH
- largest consecutive segments
- comparison with published race course

### Step 3

Convert to:

```text
database/routes/<race-name>.geojson
```

### Step 4

Add to the race seed:

```powershell
routeKey = "routes/<race-name>.geojson"
```

### Step 5

Run Terraform.

Because of the generic `fileset()` configuration, Terraform automatically uploads the new GeoJSON file.

### Step 6

Seed or update the race in DynamoDB.

### Step 7

The frontend automatically displays:

```text
View Route
```

No race-specific Angular changes are required.

---

## 37. Conclusion

The Race Route Maps feature extends the Half Marathon Cloud Platform with a complete cloud-based geospatial visualization workflow.

The implementation keeps the frontend generic, stores route data securely in AWS, retrieves route files through the backend, and uses Infrastructure as Code to automate deployment.

The final design provides:

- clear separation between application and route storage
- reusable race route handling
- private S3 route files
- scalable backend access through ECS and ALB
- automatic infrastructure provisioning
- easy addition of future race routes
- controlled Git review before integration into `main`

The feature was deployed, tested, validated, committed, pushed to GitHub, and submitted through a Pull Request for team review.

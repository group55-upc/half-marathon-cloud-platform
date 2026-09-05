# Race Route Maps Feature

This branch adds race route visualization functionality to the Half Marathon Cloud Platform.

## Main Improvements

- Added race route support using GeoJSON files.
- Added a private Amazon S3 bucket to store race route files.
- Added automatic Terraform upload for all `.geojson` files located in `database/routes`.
- Added backend support to retrieve race routes from S3.
- Added the API endpoint:

  `GET /races/:id/route`

- Added `routeKey` support to race records stored in DynamoDB.
- Added a new Angular race route page using Leaflet and OpenStreetMap.
- Added automatic START and FINISH markers.
- Added a `View Route` button only for races that have an available route.
- Added runtime frontend API configuration using `config.js`.

## Available Race Maps

The following race routes have been added and tested:

- Barcelona Half Marathon
- Madrid Half Marathon
- Valencia Half Marathon
- Lisbon Half Marathon
- Berlin Half Marathon
- Roma-Ostia Half Marathon
- Great North Run
- Copenhagen Half Marathon
- United NYC Half

The following races remain available in the application without route visualization:

- Paris Half Marathon
- Zurich Marato Barcelona
- Berlin Marathon

## Architecture

```text
Angular Frontend
      |
      | GET /races/:id/route
      v
Application Load Balancer
      |
      v
ECS Fargate / Node.js Backend
      |
      +---- DynamoDB
      |       race.routeKey
      |
      +---- Private S3 Bucket
              routes/*.geojson

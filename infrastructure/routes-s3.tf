###############################################################################
# RACE ROUTES S3 BUCKET
#
# Private bucket used to store race circuits in GeoJSON format.
# Every .geojson file located in database/routes is uploaded automatically.
#
# The backend running on ECS retrieves these files and serves them to
# the frontend through the API.
###############################################################################

locals {
  race_route_files = fileset(
    "${path.module}/../database/routes",
    "*.geojson"
  )
}

resource "aws_s3_bucket" "race-routes" {
  bucket_prefix = "marathon-routes-"
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "race-routes" {
  bucket = aws_s3_bucket.race-routes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "race-routes" {
  for_each = local.race_route_files

  bucket = aws_s3_bucket.race-routes.id
  key    = "routes/${each.value}"

  source = "${path.module}/../database/routes/${each.value}"
  etag   = filemd5("${path.module}/../database/routes/${each.value}")

  content_type = "application/geo+json"
}

###############################################################################
# RACE ROUTES S3 BUCKET
#
# Private bucket used to store race circuits in GeoJSON format.
# The backend running on ECS retrieves these files and serves them to
# the frontend through the API.
###############################################################################

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

resource "aws_s3_object" "barcelona-half-route" {
  bucket = aws_s3_bucket.race-routes.id
  key    = "routes/barcelona-half-marathon.geojson"

  source = "${path.module}/../database/routes/barcelona-half-marathon.geojson"
  etag   = filemd5("${path.module}/../database/routes/barcelona-half-marathon.geojson")

  content_type = "application/geo+json"
}

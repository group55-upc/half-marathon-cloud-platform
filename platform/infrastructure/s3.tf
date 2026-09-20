# # # S3 BUCKET FOR FRONTEND ##

# resource "aws_s3_bucket" "s3-website" {
#   bucket        = "marathon-cloudupc-website"
#   force_destroy = true
#   tags          = local.tags
# }

# resource "aws_s3_bucket_public_access_block" "s3-website" {
#   bucket = aws_s3_bucket.s3-website.id
#   # block_public_acls       = false
#   # block_public_policy     = false
#   # ignore_public_acls      = false
#   # restrict_public_buckets = false
# }

# resource "aws_s3_bucket_website_configuration" "s3-website" {
#   bucket = aws_s3_bucket.s3-website.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "index.html"
#   }
# }

# resource "aws_s3_bucket_policy" "s3-website" {
#   # depends_on = [aws_s3_bucket_public_access_block.s3-website]
#   bucket     = aws_s3_bucket.s3-website.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "${aws_s3_bucket.s3-website.arn}/*"
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket_versioning" "s3-website" {
#   bucket = aws_s3_bucket.s3-website.id

#   versioning_configuration {
#     status = "Disabled"
#   }
# }








# resource "aws_s3_bucket" "s3-marathon-app-tracks" {
#   bucket        = "fpcmarathon-tracks"
#   force_destroy = true
#   tags          = local.tags
# }

# resource "aws_s3_bucket_public_access_block" "s3-marathon-app-tracks" {
#   bucket = aws_s3_bucket.s3-marathon-app-tracks.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }


# resource "aws_s3_bucket_policy" "s3-marathon-app-tracks" {
#   bucket     = aws_s3_bucket.s3-marathon-app-tracks.id

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "PublicReadGetObject",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": "s3:GetObject",
#             "Resource": "arn:aws:s3:::fpcmarathon-tracks/*"
#         }
#     ]
# })
# }

# resource "aws_s3_bucket_cors_configuration" "s3-marathon-app-tracks" {
#   bucket = aws_s3_bucket.s3-marathon-app-tracks.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins  = ["https://cloud.fpcmarathon.upcnet.es"]
#     expose_headers  = ["ETag", "Content-Length", "Content-Range"]
#     max_age_seconds = 3000
#   }
# }


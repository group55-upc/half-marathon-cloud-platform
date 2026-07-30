## S3 BUCKET FOR FRONTEND ##

resource "aws_s3_bucket" "s3-website" {
  bucket = "marathon-cloudupc-website"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "s3-website" {
  bucket = aws_s3_bucket.s3-website.id
  # block_public_acls       = false
  # block_public_policy     = false
  # ignore_public_acls      = false
  # restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "s3-website" {
  bucket = aws_s3_bucket.s3-website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "s3-website" {
  depends_on = [aws_s3_bucket_public_access_block.s3-website]
  bucket = aws_s3_bucket.s3-website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3-website.arn}/*"
      }
    ]
  })
}

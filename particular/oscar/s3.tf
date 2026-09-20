#bucket s3 para circuitos

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "media_bucket" {
  bucket        = "${var.project_name}-data-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-storage"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "media_bucket_block" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket S3 para la Web
resource "aws_s3_bucket" "web_redirect" {
  bucket        = "${var.project_name}-web-redirect-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Desactivar el bloqueo de acceso público (Requisito para Webs en S3)
resource "aws_s3_bucket_public_access_block" "web_redirect_public" {
  bucket = aws_s3_bucket.web_redirect.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política de lectura pública para el Bucket
resource "aws_s3_bucket_policy" "web_redirect_policy" {
  bucket     = aws_s3_bucket.web_redirect.id
  depends_on = [aws_s3_bucket_public_access_block.web_redirect_public]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_redirect.arn}/*"
      }
    ]
  })
}

# Configuración del Sitio Web Estático con Redirección al Clúster ECS
resource "aws_s3_bucket_website_configuration" "web_redirect_config" {
  bucket = aws_s3_bucket.web_redirect.id

   # Configuración de redirección
  redirect_all_requests_to {
    # IMPORTANTE: Reemplaza con el DNS de tu Load Balancer / IP del Clúster ECS
    host_name = "tu-ecs-alb-123456789.us-east-1.elb.amazonaws.com"
    protocol  = "http"
  }
}

# Output para obtener la URL pública de la Web alojada en S3
output "s3_website_url" {
  description = "URL pública del S3 configurado como Sitio Web"
  value       = aws_s3_bucket_website_configuration.web_redirect_config.website_endpoint
}
resource "aws_dynamodb_table" "recorridos" {
  name         = "${var.project_name}-recorridos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "recorrido_id"
  range_key    = "timestamp"

  attribute {
    name = "recorrido_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-dynamodb"
    Environment = "Dev"
  }
}
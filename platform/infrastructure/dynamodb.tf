## DYNAMODB ##

resource "aws_dynamodb_table" "marathon-app-dynamodb-races" {
  count = var.enable-marathon-app ? 1 : 0
  name         = var.marathon-app-db-name-races
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = local.tags
}



resource "aws_dynamodb_table" "marathon-app-dynamodb-notifications" {
  count = var.enable-marathon-app ? 1 : 0
  name         = var.marathon-app-db-name-notifications
  hash_key     = "userSub"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "userSub"
    type = "S"
  }

  tags = local.tags
}
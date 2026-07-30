## DYNAMODB ##

resource "aws_dynamodb_table" "dynamodb-table-races" {
  name              = var.dynamodb-name
  hash_key          = "id"
  billing_mode      = "PAY_PER_REQUEST"

  attribute {
    name            = "id"
    type            = "S"
  }

  tags              = local.tags
}
resource "aws_cognito_user_pool" "marathon-app-user-pool" {
  count = var.enable-marathon-app ? 1 : 0
  name = "marathon-app-user-pool"

  alias_attributes = ["email"]

  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

}

resource "aws_cognito_user_pool_client" "marathon-app-cognito-client" {
  count = var.enable-marathon-app ? 1 : 0
  name         = "marathon-app-client"
  user_pool_id = aws_cognito_user_pool.marathon-app-user-pool[0].id

  generate_secret = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}
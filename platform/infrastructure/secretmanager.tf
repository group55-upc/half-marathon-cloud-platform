resource "aws_secretsmanager_secret" "marathon-app-backend" {
  count = var.enable-marathon-app ? 1 : 0
  name = "marathon-app/backend"
}

resource "aws_secretsmanager_secret_version" "marathon-app-backend" {
  count = var.enable-marathon-app ? 1 : 0
  secret_id = aws_secretsmanager_secret.marathon-app-backend[0].id

  secret_string = jsonencode({
    USER_POOL_ID  = aws_cognito_user_pool.marathon-app-user-pool[0].id
    CLIENT_ID     = aws_cognito_user_pool_client.marathon-app-cognito-client[0].id
    CLIENT_SECRET = aws_cognito_user_pool_client.marathon-app-cognito-client[0].client_secret
  })
}
data "archive_file" "notify-race" {
  type        = "zip"
  output_path = "${path.module}/../../lambda/marathon-app/notify-race.zip"

  source {
    content  = file("${path.module}/../../lambda/marathon-app/notify-race.js")
    filename = "index.mjs"
  }
}

resource "aws_lambda_function" "marathon-app-notify-races" {
  count = var.enable-marathon-app ? 1 : 0
  function_name = "notify-new-race"
  description   = "Notify to certain users when new races are published"

  role    = data.aws_iam_role.lab-role.arn
  runtime = "nodejs24.x"
  handler = "index.handler"

  filename         = data.archive_file.notify-race.output_path
  source_code_hash = data.archive_file.notify-race.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.marathon-app-notifications[0].arn
    }
  }

  tags = local.tags
}


resource "aws_lambda_event_source_mapping" "races_stream" {
  count = var.enable-marathon-app ? 1 : 0
  event_source_arn  = aws_dynamodb_table.marathon-app-dynamodb-races[0].stream_arn
  function_name     = aws_lambda_function.marathon-app-notify-races[0].arn
  enabled           = true
  batch_size        = 10
  starting_position = "LATEST"

  filter_criteria {
    filter {
      pattern = jsonencode({ eventName = ["INSERT"] })
    }
  }

  maximum_retry_attempts         = 2
  bisect_batch_on_function_error = true
  function_response_types        = ["ReportBatchItemFailures"]
}



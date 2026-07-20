# ============================================================
# DYNAMODB GATEWAY VPC ENDPOINT
# ============================================================
#
# This endpoint allows resources inside the VPC to access
# Amazon DynamoDB through the AWS network.
#
# No NAT Gateway is required for EC2-to-DynamoDB communication.
# The endpoint is associated with the public route table used
# by the backend EC2 instance.

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "AllowAccessToHalfMarathonRacesTable"
        Effect    = "Allow"
        Principal = "*"

        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:PutItem"
        ]

        Resource = [
          aws_dynamodb_table.races.arn
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-dynamodb-endpoint-${var.environment}"
  }
}

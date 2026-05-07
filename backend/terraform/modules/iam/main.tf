variable "environment" {
  type = string
}

variable "dynamodb_arns" {
  type        = list(string)
  description = "ARNs of DynamoDB tables Lambda can access"
}

# --- Lambda Execution Role ---
resource "aws_iam_role" "lambda_role" {
  name = "mechanic-master-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
      ]
      Resource = concat(
        var.dynamodb_arns,
        [for arn in var.dynamodb_arns : "${arn}/index/*"]
      )
    }]
  })
}

# Bedrock access (Nova Micro)
resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "bedrock-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = [
        "arn:aws:bedrock:*::foundation-model/amazon.nova-*",
        "arn:aws:bedrock:*:*:inference-profile/us.amazon.nova-*",
      ]
    }]
  })
}

# --- Outputs ---
output "lambda_role_arn" { value = aws_iam_role.lambda_role.arn }

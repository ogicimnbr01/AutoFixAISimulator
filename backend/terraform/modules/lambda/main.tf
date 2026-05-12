variable "environment" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "lambdas_dir" {
  type        = string
  description = "Path to lambdas source directory"
}

variable "revenuecat_webhook_secret" {
  type        = string
  description = "Bearer token expected from RevenueCat webhook requests"
  default     = ""
  sensitive   = true
}

variable "dynamodb_table_names" {
  type = map(string)
}

locals {
  lambda_functions = {
    game_handler        = { handler = "handler.lambda_handler", timeout = 30, memory = 256 }
    hint_handler        = { handler = "handler.lambda_handler", timeout = 30, memory = 256 }
    user_handler        = { handler = "handler.lambda_handler", timeout = 10, memory = 128 }
    ad_reward_handler   = { handler = "handler.lambda_handler", timeout = 10, memory = 128 }
    leaderboard_handler = { handler = "handler.lambda_handler", timeout = 10, memory = 128 }
    authorizer          = { handler = "handler.lambda_handler", timeout = 5, memory = 128 }
    revenuecat_webhook  = { handler = "handler.lambda_handler", timeout = 10, memory = 128 }
    report_handler      = { handler = "handler.lambda_handler", timeout = 10, memory = 128 }
  }

  env_vars = {
    ENVIRONMENT                = var.environment
    TABLE_USERS                = var.dynamodb_table_names["users"]
    TABLE_SESSIONS             = var.dynamodb_table_names["sessions"]
    TABLE_DAILY_RESETS         = var.dynamodb_table_names["daily_resets"]
    TABLE_LEADERBOARD          = var.dynamodb_table_names["leaderboard"]
    TABLE_REPORTS              = var.dynamodb_table_names["reports"]
    TABLE_TRANSACTIONS         = var.dynamodb_table_names["transactions"]
    TABLE_DEVICE_STATES        = var.dynamodb_table_names["device_states"]
    BEDROCK_MODEL_ID           = "us.amazon.nova-lite-v1:0"
    BEDROCK_REGION             = "us-east-1"
    ALLOW_CLIENT_AD_REWARD     = var.environment == "prod" ? "false" : "true"
    ALLOW_UNVERIFIED_ADMOB_SSV = var.environment == "prod" ? "false" : "true"
    REVENUECAT_WEBHOOK_SECRET  = var.revenuecat_webhook_secret
  }
}

# --- Shared Lambda Layer (prompts, scenarios, security) ---
data "archive_file" "shared_layer" {
  type        = "zip"
  source_dir  = "${var.lambdas_dir}/shared"
  output_path = "${path.module}/builds/shared_layer.zip"
}

resource "aws_lambda_layer_version" "shared" {
  layer_name          = "mechanic-master-shared-${var.environment}"
  filename            = data.archive_file.shared_layer.output_path
  source_code_hash    = data.archive_file.shared_layer.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

# --- Lambda Functions ---
data "archive_file" "lambda_zips" {
  for_each    = local.lambda_functions
  type        = "zip"
  source_dir  = "${var.lambdas_dir}/${each.key}"
  output_path = "${path.module}/builds/${each.key}.zip"
}

resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  function_name    = "mechanic-master-${each.key}-${var.environment}"
  role             = var.lambda_role_arn
  handler          = each.value.handler
  runtime          = "python3.12"
  timeout          = each.value.timeout
  memory_size      = each.value.memory
  filename         = data.archive_file.lambda_zips[each.key].output_path
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256
  layers           = [aws_lambda_layer_version.shared.arn]

  environment {
    variables = local.env_vars
  }

  tags = { Name = "mechanic-master-${each.key}" }
}

# --- Outputs ---
output "lambda_arns" {
  value = { for k, v in aws_lambda_function.functions : k => v.invoke_arn }
}

output "lambda_function_names" {
  value = { for k, v in aws_lambda_function.functions : k => v.function_name }
}

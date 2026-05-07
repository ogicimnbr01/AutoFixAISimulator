variable "environment" {
  type = string
}

variable "lambda_arns" {
  type = map(string)
}

variable "lambda_function_names" {
  type = map(string)
}

# --- HTTP API ---
resource "aws_apigatewayv2_api" "main" {
  name          = "mechanic-master-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 3600
  }
}

# --- Lambda Authorizer ---
resource "aws_apigatewayv2_authorizer" "firebase" {
  api_id                            = aws_apigatewayv2_api.main.id
  name                              = "firebase-auth"
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.lambda_arns["authorizer"]
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 300
  identity_sources                  = ["$request.header.Authorization"]
  enable_simple_responses           = true
}

# --- Routes ---
locals {
  routes = {
    "POST /game/start"          = "game_handler"
    "POST /game/message"        = "game_handler"
    "POST /hint"                = "hint_handler"
    "GET /user/profile"         = "user_handler"
    "POST /user/login-bonus"    = "user_handler"
    "POST /ad/reward"           = "ad_reward_handler"
    "GET /leaderboard/{period}" = "leaderboard_handler"
  }
}

resource "aws_apigatewayv2_integration" "lambdas" {
  for_each = local.routes

  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns[each.value]
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "routes" {
  for_each = local.routes

  api_id             = aws_apigatewayv2_api.main.id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.lambdas[each.key].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.firebase.id
}

# --- Stage (auto-deploy) ---
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

# --- Lambda Permissions (allow API GW to invoke) ---
resource "aws_lambda_permission" "api_gw" {
  for_each = toset(distinct(values(local.routes)))

  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names[each.value]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# authorizer permission
resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["authorizer"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.firebase.id}"
}

# --- Output ---
output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

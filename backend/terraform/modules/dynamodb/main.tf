variable "environment" {
  type = string
}

locals {
  prefix = "MechanicMaster"
}

# --- Users Table ---
resource "aws_dynamodb_table" "users" {
  name         = "${local.prefix}_Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = { Name = "${local.prefix}_Users" }
}

# --- Sessions Table ---
resource "aws_dynamodb_table" "sessions" {
  name         = "${local.prefix}_Sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = { Name = "${local.prefix}_Sessions" }
}

# --- Daily Resets Table ---
resource "aws_dynamodb_table" "daily_resets" {
  name         = "${local.prefix}_DailyResets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId_date"

  attribute {
    name = "userId_date"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = { Name = "${local.prefix}_DailyResets" }
}

# --- Leaderboard Table ---
resource "aws_dynamodb_table" "leaderboard" {
  name         = "${local.prefix}_Leaderboard"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "period"
  range_key    = "score_userId"

  attribute {
    name = "period"
    type = "S"
  }

  attribute {
    name = "score_userId"
    type = "S"
  }

  tags = { Name = "${local.prefix}_Leaderboard" }
}

# --- Reports Table ---
resource "aws_dynamodb_table" "reports" {
  name         = "${local.prefix}_Reports"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reportId"

  attribute {
    name = "reportId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }

  tags = { Name = "${local.prefix}_Reports" }
}

# --- Transactions Table ---
resource "aws_dynamodb_table" "transactions" {
  name         = "${local.prefix}_Transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transactionId"

  attribute {
    name = "transactionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = { Name = "${local.prefix}_Transactions" }
}

# --- Device Economy State Table ---
resource "aws_dynamodb_table" "device_states" {
  name         = "${local.prefix}_DeviceStates"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "deviceHash"

  attribute {
    name = "deviceHash"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = { Name = "${local.prefix}_DeviceStates" }
}

# --- Outputs ---
output "users_table_name" { value = aws_dynamodb_table.users.name }
output "users_table_arn" { value = aws_dynamodb_table.users.arn }

output "sessions_table_name" { value = aws_dynamodb_table.sessions.name }
output "sessions_table_arn" { value = aws_dynamodb_table.sessions.arn }

output "daily_resets_table_name" { value = aws_dynamodb_table.daily_resets.name }
output "daily_resets_table_arn" { value = aws_dynamodb_table.daily_resets.arn }

output "leaderboard_table_name" { value = aws_dynamodb_table.leaderboard.name }
output "leaderboard_table_arn" { value = aws_dynamodb_table.leaderboard.arn }

output "reports_table_name" { value = aws_dynamodb_table.reports.name }
output "reports_table_arn" { value = aws_dynamodb_table.reports.arn }

output "transactions_table_name" { value = aws_dynamodb_table.transactions.name }
output "transactions_table_arn" { value = aws_dynamodb_table.transactions.arn }

output "device_states_table_name" { value = aws_dynamodb_table.device_states.name }
output "device_states_table_arn" { value = aws_dynamodb_table.device_states.arn }

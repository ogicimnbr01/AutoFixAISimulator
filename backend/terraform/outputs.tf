output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = module.api_gateway.api_url
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    users        = module.dynamodb.users_table_name
    sessions     = module.dynamodb.sessions_table_name
    daily_resets = module.dynamodb.daily_resets_table_name
    leaderboard  = module.dynamodb.leaderboard_table_name
  }
}

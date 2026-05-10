variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "firebase_project_id" {
  description = "Firebase project ID for token verification"
  type        = string
  default     = "" # Set in terraform.tfvars
}

variable "revenuecat_webhook_secret" {
  description = "Bearer token expected from RevenueCat webhook requests"
  type        = string
  default     = ""
  sensitive   = true
}

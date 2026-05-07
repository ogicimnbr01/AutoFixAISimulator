terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mechanic-master-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mechanic-master-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MechanicMaster"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# --- Modules ---

module "dynamodb" {
  source      = "./modules/dynamodb"
  environment = var.environment
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
  dynamodb_arns = [
    module.dynamodb.users_table_arn,
    module.dynamodb.sessions_table_arn,
    module.dynamodb.daily_resets_table_arn,
    module.dynamodb.leaderboard_table_arn,
  ]
}

module "lambda" {
  source             = "./modules/lambda"
  environment        = var.environment
  lambda_role_arn    = module.iam.lambda_role_arn
  lambdas_dir        = "${path.root}/../lambdas"
  dynamodb_table_names = {
    users        = module.dynamodb.users_table_name
    sessions     = module.dynamodb.sessions_table_name
    daily_resets = module.dynamodb.daily_resets_table_name
    leaderboard  = module.dynamodb.leaderboard_table_name
  }
}

module "api_gateway" {
  source      = "./modules/api_gateway"
  environment = var.environment
  lambda_arns = module.lambda.lambda_arns
  lambda_function_names = module.lambda.lambda_function_names
}

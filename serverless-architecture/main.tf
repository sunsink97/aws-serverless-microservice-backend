locals {
  common_tags = {
    project   = var.project_name
    env       = var.environment
    managedby = "Terraform"
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-demo-serverless-architecture"  
    key            = "microservice-chat-bot/terraform.tfstate"
    region         = "us-east-1"                  
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

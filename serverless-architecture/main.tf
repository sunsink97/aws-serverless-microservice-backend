locals {
  common_tags = {
    project   = var.project_name
    env       = var.environment
    managedby = "Terraform"
  }
}
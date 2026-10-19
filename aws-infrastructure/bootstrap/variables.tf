variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "eu-north-1"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) whose workflows may assume the Terraform roles"
  type        = string
  default     = "nouman29/ecom-cicd"
}

variable "github_branch" {
  description = "Branch whose CD workflow may run terraform plan"
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = "GitHub environment (with required reviewers) whose jobs may run terraform apply"
  type        = string
  default     = "production"
}

variable "github_oidc_sub_prefix" {
  description = "OIDC sub prefix for the repo (immutable form, from GET /repos/{repo}/actions/oidc/customization/sub)"
  type        = string
  default     = "repo:nouman29@168075674/ecom-cicd@1421705453"
}

variable "app_state_key" {
  description = "S3 key of the app infrastructure state (managed by CI/CD)"
  type        = string
  default     = "app/terraform.tfstate"
}

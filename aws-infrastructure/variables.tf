
variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "mern-app"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Published frontend port"
  type        = number
  default     = 8080
}

variable "allowed_app_cidr" {
  description = "CIDR allowed to access the frontend"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (GitHub-hosted runners use changing IPs)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing EC2 key pair used for SSH deploys"
  type        = string
  default     = "deployment"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) cloned on EC2 and trusted by the OIDC role"
  type        = string
  default     = "nouman29/ecom-cicd"
}

variable "github_branch" {
  description = "Branch allowed to push images and deploy"
  type        = string
  default     = "main"
}

variable "github_oidc_sub_prefix" {
  description = "OIDC sub prefix for the repo (immutable form, from GET /repos/{repo}/actions/oidc/customization/sub)"
  type        = string
  default     = "repo:nouman29@168075674/ecom-cicd@1421705453"
}

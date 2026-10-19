
terraform {
  required_version = ">= 1.10.0"

  # Shared state so CI/CD and laptops see the same infrastructure (bucket created by bootstrap/)
  backend "s3" {
    bucket       = "ecom-cicd-tfstate-539893177779"
    key          = "app/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

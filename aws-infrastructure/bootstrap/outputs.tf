output "state_bucket" {
  description = "S3 bucket holding Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "terraform_plan_role_arn" {
  description = "Role for terraform plan in CI/CD (GitHub variable TF_PLAN_ROLE_ARN)"
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "Role for terraform apply in the production environment (GitHub variable TF_APPLY_ROLE_ARN)"
  value       = aws_iam_role.terraform_apply.arn
}

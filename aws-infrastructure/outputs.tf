
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "elastic_ip" {
  description = "Static public IP of the EC2 instance (GitHub variable EC2_HOST)"
  value       = aws_eip.app.public_ip
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_eip.app.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH into the instance (run from ecom-store/)"
  value       = "ssh -i deployment.pem ubuntu@${aws_eip.app.public_ip}"
}

output "ecr_registry" {
  description = "ECR registry host (GitHub variable ECR_REGISTRY)"
  value       = local.ecr_registry
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for name, repo in aws_ecr_repository.app : name => repo.repository_url }
}

output "github_actions_role_arn" {
  description = "IAM role assumed by GitHub Actions (GitHub variable AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}

output "aws_region" {
  description = "AWS deployment region"
  value       = var.aws_region
}

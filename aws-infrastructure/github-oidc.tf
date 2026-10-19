
# GitHub OIDC provider lives in bootstrap/ (shared with the Terraform roles)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Hand the provider over to bootstrap/ without deleting it
removed {
  from = aws_iam_openid_connect_provider.github

  lifecycle {
    destroy = false
  }
}

# Role assumed by the deploy workflow, only from the configured repo and branch
resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecr-push"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # Immutable subject (owner/repo IDs) as sent by this repo, plus the classic name-based form
          "token.actions.githubusercontent.com:sub" = [
            "${var.github_oidc_sub_prefix}:ref:refs/heads/${var.github_branch}",
            "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          ]
        }
      }
    }]
  })
}

# Push and pull images to the app repositories only
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [for repo in aws_ecr_repository.app : repo.arn]
      }
    ]
  })
}

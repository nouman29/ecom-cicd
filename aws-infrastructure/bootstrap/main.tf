# One-time setup, applied by hand (never by CI/CD):
# remote state bucket, GitHub OIDC provider, and the roles the pipeline uses for terraform plan/apply.
# Keeping these out of the app config means the pipeline can never lock itself out.

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "ecom-cicd-tfstate-${local.account_id}"
  oidc_url     = "token.actions.githubusercontent.com"
}

# ---------- Remote state ----------

resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.state_bucket
    ManagedBy = "Terraform-bootstrap"
  }
}

# Every state write is kept, so a bad apply can be rolled back
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- GitHub OIDC ----------

# Created earlier by the app config; adopted here so app applies can't remove it
import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::539893177779:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_url}"
  client_id_list = ["sts.amazonaws.com"]
}

# Trust policy for GitHub Actions jobs whose OIDC subject matches one of the given suffixes
data "aws_iam_policy_document" "trust" {
  for_each = {
    # Pull requests (CI plan) and pushes to main (CD plan)
    plan = ["pull_request", "ref:refs/heads/${var.github_branch}"]
    # Only jobs running in the protected environment, i.e. after a reviewer approved
    apply = ["environment:${var.github_environment}"]
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Immutable subject (owner/repo IDs) as sent by this repo, plus the classic name-based form
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values = flatten([
        for suffix in each.value : [
          "${var.github_oidc_sub_prefix}:${suffix}",
          "repo:${var.github_repo}:${suffix}"
        ]
      ])
    }
  }
}

# ---------- terraform plan role (read-only) ----------

resource "aws_iam_role" "terraform_plan" {
  name               = "ecom-cicd-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.trust["plan"].json
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plan takes the state lock, so it needs to write/delete the lock file only
resource "aws_iam_role_policy" "plan_state_lock" {
  name = "state-lock"
  role = aws_iam_role.terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:DeleteObject"]
      Resource = "${aws_s3_bucket.tfstate.arn}/${var.app_state_key}.tflock"
    }]
  })
}

# ---------- terraform apply role ----------

resource "aws_iam_role" "terraform_apply" {
  name               = "ecom-cicd-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.trust["apply"].json
}

# Everything except IAM/Organizations; IAM is granted narrowly below
resource "aws_iam_role_policy_attachment" "apply_power_user" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "apply_scoped" {
  name = "app-iam-and-state"
  role = aws_iam_role.terraform_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadIam"
        Effect   = "Allow"
        Action   = ["iam:Get*", "iam:List*"]
        Resource = "*"
      },
      {
        # Only the app's own roles/profiles; never the bootstrap roles above
        Sid    = "ManageAppIam"
        Effect = "Allow"
        Action = ["iam:*"]
        Resource = [
          "arn:aws:iam::${local.account_id}:role/mern-app-*",
          "arn:aws:iam::${local.account_id}:instance-profile/mern-app-*",
          "arn:aws:iam::${local.account_id}:role/github-actions-ecr-push"
        ]
      },
      {
        Sid      = "AppState"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.tfstate.arn}/app/*"
      },
      {
        # Power-user S3 access must not touch the bucket itself or the bootstrap state
        Sid    = "ProtectStateBucket"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket*",
          "s3:PutBucket*",
          "s3:PutLifecycleConfiguration",
          "s3:PutEncryptionConfiguration"
        ]
        Resource = aws_s3_bucket.tfstate.arn
      },
      {
        Sid      = "ProtectBootstrapState"
        Effect   = "Deny"
        Action   = ["s3:PutObject", "s3:DeleteObject*"]
        Resource = "${aws_s3_bucket.tfstate.arn}/bootstrap/*"
      }
    ]
  })
}

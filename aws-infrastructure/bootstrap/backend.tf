# Bootstrap state lives in the bucket it created (moved there with `terraform init -migrate-state`)
terraform {
  backend "s3" {
    bucket       = "ecom-cicd-tfstate-539893177779"
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

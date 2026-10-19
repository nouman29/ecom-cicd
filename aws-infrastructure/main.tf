
data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Find the existing default VPC
data "aws_vpc" "default" {
  default = true
}

# Find subnets inside the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Find the latest Ubuntu 24.04 LTS AMD64 image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for the application
resource "aws_security_group" "app" {
  name        = "mern-app-sg"
  description = "Allow web traffic to the MERN frontend and SSH for deploys"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Frontend access"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_app_cidr]
  }

  ingress {
    description = "SSH for GitHub Actions deploys (key-only auth)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mern-app-sg"
  }
}

# Allow EC2 to assume an IAM role
resource "aws_iam_role" "ec2" {
  name = "mern-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Permit secure Session Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Permit EC2 to pull private images from ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "mern-app-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Create the EC2 instance
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Swap, Docker, Compose, git, ECR credential helper, then clone the repo
  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    set -eux

    # 2 GB swap so MongoDB + Node fit on a small instance
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    apt-get update
    apt-get install -y docker.io docker-compose-v2 git amazon-ecr-credential-helper

    systemctl enable --now docker
    usermod -aG docker ubuntu

    # Docker pulls from ECR using the instance role
    mkdir -p /home/ubuntu/.docker
    cat > /home/ubuntu/.docker/config.json <<JSON
    { "credHelpers": { "${local.ecr_registry}": "ecr-login" } }
    JSON
    chown -R ubuntu:ubuntu /home/ubuntu/.docker

    # App repo: holds docker-compose.prod.yml used by the deploy workflow
    if [ ! -d /home/ubuntu/app/.git ]; then
      sudo -u ubuntu git clone --branch ${var.github_branch} https://github.com/${var.github_repo}.git /home/ubuntu/app
    fi
  EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "mern-app-server"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }

  # A newer Ubuntu AMI must not replace the server (and its MongoDB data) on a routine CD run
  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.ecr_read
  ]
}

# Static public IP so EC2_HOST and CLIENT_URL survive stop/start
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "mern-app-eip"
  }
}

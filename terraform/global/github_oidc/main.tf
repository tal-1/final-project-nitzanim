provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 1. GitHub OIDC Identity Provider
# ==========================================
# This tells AWS to trust GitHub's token verification system

# 1. Dynamically fetch GitHub's current TLS certificate
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# 2. GitHub OIDC Identity Provider (Now Dynamic!)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  # Inject the dynamically fetched thumbprint here
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# ==========================================
# 2. The IAM Role for GitHub Actions
# ==========================================
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

  # This policy dictates EXACTLY who is allowed to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        # IMPORTANT: Change "YourGitHubUsername/YourRepoName" to your actual GitHub info!
        # If you don't do this, ANY repository on GitHub could technically deploy to your AWS account.
        "StringLike" : {
          "token.actions.githubusercontent.com:sub" : "repo:tal-1/final-project-nitzanim:*"
        },
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })
}

# ==========================================
# 3. Role Permissions (What GitHub is allowed to do)
# ==========================================
# We are granting AdministratorAccess because Terraform needs to build VPCs, 
# Security Groups, Databases, and IAM roles. 
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

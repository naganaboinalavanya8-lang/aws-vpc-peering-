# Credentials are NOT written here. Terraform reads them from your environment
# (for example `aws configure` or `aws sso login`). Never put keys in .tf files.
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

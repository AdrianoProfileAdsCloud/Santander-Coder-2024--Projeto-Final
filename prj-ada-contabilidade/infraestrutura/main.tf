
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.79.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      projeto = "SantanderCoders 2024 - Trilha DevOps"
      dono    = "Adriano Aparecido da Silva"
    }
  }
}

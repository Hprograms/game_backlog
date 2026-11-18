terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# SSL証明書発行用
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# 現在のAWSアカウント情報を取得
data "aws_caller_identity" "current" {}

# 現在のリージョン情報を取得
data "aws_region" "current" {}


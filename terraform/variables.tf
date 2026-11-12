variable "db_password" {
  description = "RDSのパスワード"
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWSアクセスキー"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWSシークレットキー"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  type = string
}

variable "ecs_public_ip" {
  type = string
}

variable "rails_master_key" { sensitive = true }
variable "igdb_client_id" { sensitive = true }
variable "igdb_client_secret" { sensitive = true }
variable "clerk_publishable_key" { sensitive = true }
variable "clerk_secret_key" { sensitive = true }
variable "deepl_api_key" { sensitive = true }
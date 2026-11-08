resource "aws_s3_bucket" "app_storage" {
  bucket = "tsumiquest-image-bucket"
}

# バケット自体は非公開に設定
resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket                  = aws_s3_bucket.app_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
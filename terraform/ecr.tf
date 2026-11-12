resource "aws_ecr_repository" "rails" {
  name                 = "tsumiquest-rails"
  image_tag_mutability = "MUTABLE"

  # プッシュ時に脆弱性スキャンを自動実行する設定
  image_scanning_configuration {
    scan_on_push = true
  }
}
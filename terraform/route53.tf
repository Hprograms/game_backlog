# 1〜4行目の既存の aws_route53_zone ブロックはそのまま残す
resource "aws_route53_zone" "main" {
  name = "tsumiquest.com"

  lifecycle {
    prevent_destroy = true
  }
}

# 公開ドメイン -> CloudFront へ向ける（古い app 定義は削除してこちらに差し替え）
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "tsumiquest.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudFrontのオリジン用 -> GitHub Actionsが最新Fargate IPで上書きする
resource "aws_route53_record" "origin" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "origin.tsumiquest.com"
  type    = "A"
  ttl     = 60
  records = ["127.0.0.1"]

  lifecycle {
    ignore_changes = [records]
  }
}
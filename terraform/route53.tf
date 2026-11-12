# ホストゾーンの作成
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.ecs_public_ip]
}

# 取得したドメインのネームサーバー設定に使う情報を出力
output "route53_name_servers" {
  description = "Name servers for the Route 53 zone"
  value       = aws_route53_zone.main.name_servers
}

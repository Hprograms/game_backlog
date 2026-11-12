# S3へのアクセス制御（OAC）
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "tsumiquest-s3-oac"
  description                       = "OAC for Tsumiquest S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront ディストリビューション
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.app_storage.bucket_regional_domain_name
    origin_id                = "S3-tsumiquest-image-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CDN for Tsumiquest S3"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-tsumiquest-image-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
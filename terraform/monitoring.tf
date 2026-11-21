# ==========================================
# 1. Amazon SNS トピック
# ==========================================
resource "aws_sns_topic" "alerts" {
  name = "tsumiquest-alerts-topic"

  tags = {
    Name = "tsumiquest-alerts-topic"
  }
}

# ==========================================
# 2. アプリケーションエラー監視 (CloudWatch Logs)
# ==========================================
# Railsログに「Completed 500」または「FATAL」が出力されたらカウントするフィルター
resource "aws_cloudwatch_log_metric_filter" "rails_500_error" {
  name           = "tsumiquest-rails-500-error"
  pattern        = "?\"Completed 500\" ?\"FATAL\""
  log_group_name = aws_cloudwatch_log_group.ecs.name

  metric_transformation {
    name      = "Rails500ErrorCount"
    namespace = "TsumiQuest/Application"
    value     = "1"
  }
}

# 5分間に1回でも500エラーが発生したらアラーム発火
resource "aws_cloudwatch_metric_alarm" "rails_500_error" {
  alarm_name          = "tsumiquest-rails-500-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Rails500ErrorCount"
  namespace           = "TsumiQuest/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Railsアプリケーションで500エラー（またはFATALログ）が検知されました。"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ==========================================
# 3. インフラリソース監視 (ECS CPU / メモリ)
# ==========================================
# ECS CPU使用率が85%を超えた状態が5分間続いたらアラーム発火
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "tsumiquest-ecs-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS FargateのCPU使用率が85%を超過しました。"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "tsumiquest-ecs"
    ServiceName = "tsumiquest-ecs-service"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ECS メモリ使用率が85%を超えた状態が5分間続いたらアラーム発火
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "tsumiquest-ecs-high-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS Fargateのメモリ使用率が85%を超過しました。"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "tsumiquest-ecs"
    ServiceName = "tsumiquest-ecs-service"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
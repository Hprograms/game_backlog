# 1. SSM Parameter Store に登録した Discord Webhook URL を取得
data "aws_ssm_parameter" "discord_webhook_url" {
  name            = "/tsumiquest/DISCORD_WEBHOOK_URL"
  with_decryption = true
}

# 2.  Go バイナリを自動で ZIP 化
data "archive_file" "discord_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/discord_notifier/bootstrap"
  output_path = "${path.module}/lambda/discord_notifier/discord_notifier.zip"
}

# 3. AWS Lambda 関数の作成
resource "aws_lambda_function" "discord_notifier" {
  function_name = "tsumiquest-discord-notifier"
  role          = aws_iam_role.lambda_discord_notifier.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["x86_64"]

  filename         = data.archive_file.discord_notifier.output_path
  source_code_hash = data.archive_file.discord_notifier.output_base64sha256

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = data.aws_ssm_parameter.discord_webhook_url.value
    }
  }

  tags = {
    Name = "tsumiquest-discord-notifier"
  }
}

# SNSトピックからのメッセージをLambdaへ転送する紐づけ
resource "aws_sns_topic_subscription" "discord_notifier" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_notifier.arn
}

# SNSサービスがこのLambda関数を呼び出すことを許可する権限
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
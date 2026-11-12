resource "aws_ecs_cluster" "main" {
  name = "tsumiquest-ecs"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/tsumiquest-ecs"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "app" {
  family                   = "tsumiquest-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "rails"
      image     = "${aws_ecr_repository.rails.repository_url}:latest"
      essential = true
      command   = ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails db:seed && rm -f tmp/pids/server.pid && bundle exec rails s -p 80 -b '0.0.0.0'"]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "RAILS_ENV", value = "production" },
        { name = "RAILS_LOG_TO_STDOUT", value = "true" },
        { name = "DATABASE_URL", value = "postgres://postgres:${urlencode(var.db_password)}@${aws_db_instance.main.endpoint}/tsumiquest_production" },
        { name = "RAILS_SERVE_STATIC_FILES", value = "true" },
        { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:6379/0" },
        { name = "AWS_BUCKET", value = aws_s3_bucket.app_storage.bucket },
        { name = "AWS_REGION", value = "ap-northeast-1" }
      ]
      secrets = [
        { name = "AWS_ACCESS_KEY_ID", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/aws_access_key_id" },
        { name = "AWS_SECRET_ACCESS_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/aws_secret_access_key" },
        { name = "RAILS_MASTER_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/rails_master_key" },
        { name = "IGDB_CLIENT_ID", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/igdb_client_id" },
        { name = "IGDB_CLIENT_SECRET", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/igdb_client_secret" },
        { name = "CLERK_PUBLISHABLE_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/clerk_publishable_key" },
        { name = "CLERK_SECRET_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/clerk_secret_key" },
        { name = "DEEPL_API_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tsumiquest/production/deepl_api_key" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/tsumiquest-ecs"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "tsumiquest-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
}
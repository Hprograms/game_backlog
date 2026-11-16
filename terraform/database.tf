# SSMからデータベースパスワードを取得
data "aws_ssm_parameter" "db_password" {
  name            = "/tsumiquest/production/db_password" 
  with_decryption = true
}

resource "aws_db_subnet_group" "main" {
  name       = "tsumiquest-db-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}

resource "aws_db_instance" "main" {
  identifier             = "tsumiquest-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "tsumiquest_production"
  username               = "postgres"
  password               = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}
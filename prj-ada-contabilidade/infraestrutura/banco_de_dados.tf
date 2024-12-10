# RDS - O Amazon RDS é um serviço gerenciado de banco de dados para facilitar a configuração, a operação e o escalonamento
# de bancos de dados na AWS.

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rdb_us_east_1a.id, aws_subnet.rdb_us_east_1b.id]
  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "sql_server" {
  allocated_storage       = var.allocated_storage
  engine                  = var.engine
  engine_version          = "15.00.4073.23.v1"
  instance_class          = "db.m5.large"
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  multi_az                = true
  license_model           = "license-included" # Add the appropriate license model
  backup_retention_period = 1                  # Define um período de retenção maior que zero.
  tags = {
    Name = "sql-server-rds"
  }
}

output "rds_sql_server_endpoint" {
  value = aws_db_instance.sql_server.endpoint
}

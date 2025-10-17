resource "aws_security_group" "security_group_rds" {
  name        = "${var.project}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id #"${var.vpc_id}"

  tags = local.tags
}

resource "aws_security_group_rule" "lambda_access" {
  description              = "Allow Lambda SG to access RDS SG on port 5432"
  security_group_id        = aws_security_group.security_group_rds.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_lambda.id #####change oftrer moodularizatiuon#
}

resource "aws_db_subnet_group" "dbsubnet" {
  name        = "${var.project}-subnet-group-db"
  description = "Subnet group for RDS service"
  subnet_ids  = [for subnet in aws_subnet.private : subnet.id] #var.subnets_ids #module.network.lambda_subnet_ids
  tags = merge(local.tags, {
    Name = "${var.project}-subnet-group"
  })
}


resource "aws_db_instance" "db_instance" {
  identifier            = "${var.project}-db-rds"
  engine                = var.engine #"postgres"
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  db_name               = var.dbname

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  #maintenance_window     = var.maintenance_window

  skip_final_snapshot         = true
  storage_encrypted           = var.storage_encrypted
  username                    = var.username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.dbsubnet.name
  vpc_security_group_ids = [aws_security_group.security_group_rds.id]
  copy_tags_to_snapshot  = true
  tags                   = local.tags
}

output "db_instance_master_user_secret_arn" {
  description = "The ARN of the master user secret"
  value       = aws_db_instance.db_instance.master_user_secret[0].secret_arn
}

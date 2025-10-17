
# DATA
data "aws_region" "current" {}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project}-lambda-policy"
  description = "Policy for accessing System manager to obtain credentials from DB"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Logging",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SecretsAccess",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecrets"
            ],
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:rds*"
            ]
        },
        {
          "Sid": "EC2PolicyStatement",
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:AttachNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DetachNetworkInterface",
            "ec2:ModifyNetworkInterfaceAttribute"
          ],
            "Resource": [
                "arn:aws:ec2:*:*:elastic-ip/*",
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:prefix-list/*",
                "arn:aws:ec2:*:*:security-group-rule/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:subnet/*",
                "arn:aws:ec2:*:*:vpc/*",
                "arn:aws:ec2:*:*:vpc-endpoint/*",
                "arn:aws:ec2:*:*:*/*"
            ]
        },
        {
          "Sid": "EC2PolicyStatement2",
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeRouteTables"
          ],
          "Resource": "*"
        }
    ]
}
EOF
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


## SG
resource "aws_security_group" "security_group_lambda" {
  name        = "${var.project}-lambda-sg"
  description = "Sg para lambda"
  vpc_id      = aws_vpc.vpc.id #"${var.vpc_id}"
  tags        = local.tags
}

resource "aws_security_group_rule" "lambda_to_rds" {
  security_group_id        = aws_security_group.security_group_lambda.id
  type                     = "egress"
  description              = "Allow PostgreSQL traffic to RDS"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_rds.id
}

resource "aws_security_group_rule" "lambda_to_internet" {
  security_group_id = aws_security_group.security_group_lambda.id
  type              = "egress"
  description       = "Allow HTTPS egress for AWS service access"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  description         = "Python-PostgreSQL Database Adapter lambda layer"
  filename            = "${path.module}/lambda_layers/lambda-layer.zip"
  layer_name          = "psycopg2-lambda-layer"
  compatible_runtimes = ["python3.10"]
  source_code_hash    = filebase64sha256("${path.module}/lambda_layers/lambda-layer.zip")
}


## LAMBDA
resource "aws_lambda_function" "lambda-function" {
  function_name    = "${var.project}-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  runtime          = "python3.10"
  timeout          = 360
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private : subnet.id] #var.subnets_ids #module.network.lambda_subnet_ids
    security_group_ids = [aws_security_group.security_group_lambda.id]
  }

  environment {
    variables = {
      DB_ENDPOINT_ADDRESS = aws_db_instance.db_instance.address
      DB_NAME             = aws_db_instance.db_instance.db_name
      DB_PORT             = aws_db_instance.db_instance.port
      DB_SECRET_ARN       = aws_db_instance.db_instance.master_user_secret[0].secret_arn
      REGION              = data.aws_region.current.name

    }
  }
  tags = local.tags
}


resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

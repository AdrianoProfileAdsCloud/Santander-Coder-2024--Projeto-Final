
# SQS Queue Policy for S3 to send messages
resource "aws_sqs_queue_policy" "s3_to_sqs_policy" {
  queue_url = aws_sqs_queue.prj_devops_2024_sqs_standard.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action    = "sqs:SendMessage",
        Resource  = aws_sqs_queue.prj_devops_2024_sqs_standard.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.prj_devops_2024_s3.arn
          }
        }
      }
    ]
  })
}
# IAM Role for Lambdas
resource "aws_iam_role" "lambda_role" {
  name = "prj-lambda-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# A declaração data "aws_region" "current" {} e data "aws_caller_identity" "current" {} foi necessárias para poder
# construir dinamicamente o ARN de recursos relacionados ao CloudWatch Logs para a  conta e região.
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Criando a Política IAM que permite à função Lambda criar grupos de logs, fluxos de logs e enviar eventos de logs para o CloudWatch Logs.
resource "aws_iam_policy" "lambda_policy" {
  name = "prj-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject"],
        Effect = "Allow",
        Resource = "${aws_s3_bucket.prj_devops_2024_s3.arn}/*"
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect = "Allow",
        Resource = aws_sqs_queue.prj_devops_2024_sqs_standard.arn
      },
      {
        Action = "sns:Publish",
        Effect = "Allow",
        Resource = aws_sns_topic.email_notifications.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"  # Permite acesso ao CloudWatch Logs para todas as regiões e contas
      },
      {
        # Permissões específicas para a função Lambda gravar logs no CloudWatch
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
      {
        
        Action   = "rds:DescribeDBInstances",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect: "Allow",
        Action: "rds-db:connect",  
        Resource: "arn:aws:rds-db:us-east-1:123456789012:dbuser/admin"
      }
    ]
  })
}

# Anexa a política criada à role da função Lambda.
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
resource "aws_security_group" "lambda" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

#resource "aws_iam_policy_attachment" "lambda_vpc_policy" {
 # name       = "lambda-vpc-policy"
  #roles      = [aws_iam_role.lambda_role.name]
  #policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
#}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_s3_files.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.prj_devops_2024_s3.arn
}
resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}
#  Permiti tráfego especificamente da função Lambda para o banco RDS estou definindo em cidr_blocks por security_groups.
#  Desta forma é criada uma regra onde o tráfego entre o Security Group do Lambda e o Security Group do RDS é permitido, sem a necessidade 
#  de especificar intervalos de IPs.
resource "aws_security_group_rule" "rds_ingress_lambda" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
}

# Lambda to Process S3 Files
# Estou compactando o diretório ao invés de ser somente o aquivo, porque no diretório ja esta instalado a depencia do Mysql
# que a Função lambda não faz a importação
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "lambda_package"
  output_path = "lambda_package.zip"
}

resource "aws_lambda_function" "process_s3_files" {
  function_name = "process_s3_files"
  runtime       = "python3.9"
  handler       = "process_s3_file.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_package.output_path

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.email_notifications.arn
    }
  }
}

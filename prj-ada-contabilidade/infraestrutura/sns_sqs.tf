resource "aws_sns_topic" "email_notifications" {
  name = "prj-devops-2024-sns"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_notifications.arn
  protocol  = "email"
  endpoint  = var.endereco_de_email
}

resource "aws_sqs_queue" "prj_devops_2024_sqs_standard" {
  name                      = "prj-devops-2024-sqs-standard"
  delay_seconds             = 0
  message_retention_seconds = 345600

  tags = {
    Name        = "prj_devops_2024"
    Environment = var.environment
  }
}


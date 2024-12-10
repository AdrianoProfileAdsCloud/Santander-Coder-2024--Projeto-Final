resource "aws_s3_bucket" "prj_devops_2024_s3" {
  bucket = var.bucket_name

  tags = {
    Name        = "prj_devops_2024"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_notification" "bucket_notifications" {
  bucket = aws_s3_bucket.prj_devops_2024_s3.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_s3_files.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "kafka_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.kafka_bucket.arn}/*"
      },
      {
        Action = ["logs:*"]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

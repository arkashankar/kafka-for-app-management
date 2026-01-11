resource "null_resource" "build_layer" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOF
docker run --rm -v ${path.module}:/var/task public.ecr.aws/sam/build-python3.11 bash -c "cd /var/task && rm -rf layer_build && mkdir -p layer_build/python && pip install -r layers/requirements.txt -t layer_build/python"
EOF
  }

  triggers = {
    requirements = filemd5("${path.module}/layers/requirements.txt")
  }
}


resource "null_resource" "zip_layer" {
  depends_on = [null_resource.build_layer]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOF
docker run --rm -v ${path.module}:/var/task public.ecr.aws/sam/build-python3.11 bash -c "cd /var/task && zip -r kafka-layer.zip layer_build"
EOF
  }
}




resource "aws_lambda_layer_version" "kafka_layer" {
  depends_on = [null_resource.zip_layer]

  filename   = "${path.module}/kafka-layer.zip"
  layer_name = "kafka-python-layer"

  compatible_runtimes = ["python3.11"]
}



data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "consumer" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "kafka-s3-consumer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "consumer.lambda_handler"
  runtime       = "python3.11"

  layers = [aws_lambda_layer_version.kafka_layer.arn]

  environment {
    variables = {
      KAFKA_BOOTSTRAP = "44.202.245.232:9092"
      S3_BUCKET      = aws_s3_bucket.kafka_bucket.bucket
    }
  }
}

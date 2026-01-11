resource "aws_s3_bucket" "kafka_bucket" {
  bucket = "my-kafka-orders-${random_id.id.hex}"
}

resource "random_id" "id" {
  byte_length = 4
}

from kafka import KafkaConsumer
import json
import boto3
import os
import time

s3 = boto3.client("s3")

consumer = KafkaConsumer(
    "orders",
    bootstrap_servers=os.environ["KAFKA_BOOTSTRAP"],
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    group_id="lambda-consumer"
)

def lambda_handler(event, context):
    for message in consumer:
        order = message.value
        key = f"orders/{int(time.time())}.json"

        s3.put_object(
            Bucket=os.environ["S3_BUCKET"],
            Key=key,
            Body=json.dumps(order)
        )

        return {
            "statusCode": 200,
            "body": "Message written to S3"
        }

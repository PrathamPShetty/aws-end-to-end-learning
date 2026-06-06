import json
import os
import uuid
import boto3
from datetime import datetime

ENDPOINT = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost.localstack.cloud:4566')
REGION   = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')

def client(service):
    return boto3.client(service, endpoint_url=ENDPOINT, region_name=REGION)

def lambda_handler(event, context):
    order_id = 'ORD-' + str(uuid.uuid4())[:8].upper()
    now      = datetime.utcnow().isoformat()

    order = {
        'orderId':    {'S': order_id},
        'customerId': {'S': event['customerId']},
        'product':    {'S': event['product']},
        'quantity':   {'N': str(event['quantity'])},
        'price':      {'N': str(event['price'])},
        'status':     {'S': 'PLACED'},
        'createdAt':  {'S': now},
    }

    # 1. Save order to DynamoDB
    client('dynamodb').put_item(TableName='Orders', Item=order)
    print(f"[DynamoDB] Saved order {order_id}")

    # 2. Fan-out via SNS → SQS queues (notification + inventory)
    payload = json.dumps({
        'orderId':    order_id,
        'customerId': event['customerId'],
        'product':    event['product'],
        'quantity':   event['quantity'],
        'price':      event['price'],
    })
    client('sns').publish(
        TopicArn=os.environ['SNS_TOPIC_ARN'],
        Message=payload,
        Subject='order_placed',
    )
    print(f"[SNS] Published order_placed event")

    # 3. Push analytics event to Kinesis
    client('kinesis').put_record(
        StreamName='order-analytics',
        Data=json.dumps({'orderId': order_id, 'event': 'order_placed', 'ts': now}),
        PartitionKey=order_id,
    )
    print(f"[Kinesis] Streamed analytics event")

    return {'statusCode': 200, 'body': json.dumps({'orderId': order_id, 'status': 'PLACED'})}

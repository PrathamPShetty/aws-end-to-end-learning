import json
import os
import boto3

ENDPOINT = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost.localstack.cloud:4566')
REGION   = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')

def client(service):
    return boto3.client(service, endpoint_url=ENDPOINT, region_name=REGION)

def lambda_handler(event, context):
    ddb = client('dynamodb')

    for record in event['Records']:
        body  = json.loads(record['body'])
        order = json.loads(body['Message']) if 'Message' in body else body

        product  = order['product']
        quantity = int(order['quantity'])

        try:
            ddb.update_item(
                TableName='Inventory',
                Key={'productId': {'S': product}},
                UpdateExpression='SET stock = stock - :qty',
                ConditionExpression='stock >= :qty',
                ExpressionAttributeValues={':qty': {'N': str(quantity)}},
            )
            print(f"[DynamoDB] Inventory updated: {product} -{quantity} units")
        except ddb.exceptions.ConditionalCheckFailedException:
            print(f"[DynamoDB] Insufficient stock for {product}")

    return {'processed': len(event['Records'])}

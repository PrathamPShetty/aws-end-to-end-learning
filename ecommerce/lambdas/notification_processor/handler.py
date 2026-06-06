import json
import os
import boto3
from datetime import datetime

ENDPOINT = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost.localstack.cloud:4566')
REGION   = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')
BUCKET   = os.environ.get('INVOICE_BUCKET', 'ecommerce-invoices')

def client(service):
    return boto3.client(service, endpoint_url=ENDPOINT, region_name=REGION)

def lambda_handler(event, context):
    s3 = client('s3')

    for record in event['Records']:
        body  = json.loads(record['body'])
        order = json.loads(body['Message']) if 'Message' in body else body

        order_id = order['orderId']
        total    = float(order['price']) * int(order['quantity'])

        invoice = {
            'invoiceId':  f"INV-{order_id}",
            'orderId':    order_id,
            'customerId': order['customerId'],
            'product':    order['product'],
            'quantity':   order['quantity'],
            'unitPrice':  order['price'],
            'total':      round(total, 2),
            'issuedAt':   datetime.utcnow().isoformat(),
            'status':     'PAID',
        }

        s3.put_object(
            Bucket=BUCKET,
            Key=f"invoices/{order_id}.json",
            Body=json.dumps(invoice, indent=2),
            ContentType='application/json',
        )
        print(f"[S3] Invoice created: invoices/{order_id}.json  total=${total:.2f}")

    return {'processed': len(event['Records'])}

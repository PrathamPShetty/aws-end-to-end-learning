#!/bin/bash
# ============================================================
# Kinesis Firehose (Data Firehose) Demo
# Purpose: Create delivery stream to S3, put records, verify delivery
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUCKET="demo-firehose-bucket"
STREAM_NAME="demo-firehose-stream"
ROLE_ARN="arn:aws:iam::000000000000:role/firehose-role"

echo "==> Creating S3 bucket for delivery target..."
awslocal s3 mb "s3://$BUCKET" || true
echo "Bucket: $BUCKET"

echo "==> Creating Firehose delivery stream to S3..."
awslocal firehose create-delivery-stream \
  --delivery-stream-name "$STREAM_NAME" --delivery-stream-type DirectPut \
  --s3-destination-configuration "{\"RoleARN\":\"$ROLE_ARN\",\"BucketARN\":\"arn:aws:s3:::$BUCKET\",\"Prefix\":\"events/\",\"BufferingHints\":{\"SizeInMBs\":1,\"IntervalInSeconds\":60},\"CompressionFormat\":\"UNCOMPRESSED\"}" || true
echo "Delivery stream created."

echo "==> Waiting for stream to become ACTIVE..."
for i in $(seq 1 15); do
  STATUS=$(awslocal firehose describe-delivery-stream \
    --delivery-stream-name "$STREAM_NAME" \
    --output text --query 'DeliveryStreamDescription.DeliveryStreamStatus')
  echo "  Status: $STATUS"
  [ "$STATUS" = "ACTIVE" ] && break
  sleep 1
done

echo "==> Putting records into Firehose..."
awslocal firehose put-record \
  --delivery-stream-name "$STREAM_NAME" \
  --record '{"Data":"eyJldmVudCI6ImxvZ2luIiwidXNlcklkIjoidTEiLCJ0cyI6IjIwMjYtMDEtMDFUMDA6MDA6MDBaIn0K"}'

awslocal firehose put-record-batch \
  --delivery-stream-name "$STREAM_NAME" \
  --records '[
    {"Data":"eyJldmVudCI6InBhZ2VfdmlldyIsInBhZ2UiOiIvaG9tZSJ9Cg=="},
    {"Data":"eyJldmVudCI6ImNsaWNrIiwiZWxlbWVudCI6ImJ1eS1idXR0b24ifQo="}
  ]'
echo "Records submitted to Firehose."

echo "==> Listing S3 objects (may take a moment to flush)..."
sleep 3
awslocal s3 ls "s3://$BUCKET/events/" --recursive || echo "  (buffering - may not be flushed yet)"
echo "==> Delivery stream status:"
awslocal firehose describe-delivery-stream --delivery-stream-name "$STREAM_NAME" \
  --output text --query 'DeliveryStreamDescription.{Name:DeliveryStreamName,Status:DeliveryStreamStatus}'
echo "==> Firehose demo complete."

#!/bin/bash
# ============================================================
# SQS (Simple Queue Service) Demo
# Purpose: Create queues, send/receive messages, use DLQ
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "==> Creating Dead Letter Queue..."
DLQ_URL=$(awslocal sqs create-queue --queue-name demo-dlq \
  --output text --query 'QueueUrl') || true
DLQ_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url "$DLQ_URL" \
  --attribute-names QueueArn \
  --output text --query 'Attributes.QueueArn')
echo "DLQ ARN: $DLQ_ARN"

echo "==> Creating main queue with DLQ redrive policy..."
awslocal sqs create-queue \
  --queue-name demo-main-queue \
  --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}" || true
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name demo-main-queue --output text --query 'QueueUrl')
echo "Queue URL: $QUEUE_URL"

echo "==> Sending messages..."
awslocal sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"event":"order_placed","orderId":"ORD-001","amount":99.99}'
awslocal sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"event":"order_placed","orderId":"ORD-002","amount":149.99}' \
  --message-attributes '{"Priority":{"DataType":"String","StringValue":"high"}}'
echo "Messages sent."

echo "==> Receiving messages..."
MESSAGES=$(awslocal sqs receive-message --queue-url "$QUEUE_URL" \
  --max-number-of-messages 5 --wait-time-seconds 1)
echo "$MESSAGES" | python3 -m json.tool

RECEIPT=$(echo "$MESSAGES" | python3 -c "import sys,json; msgs=json.load(sys.stdin).get('Messages',[]); print(msgs[0]['ReceiptHandle']) if msgs else print('')")
if [ -n "$RECEIPT" ]; then
  echo "==> Deleting first received message..."
  awslocal sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$RECEIPT"
  echo "Message deleted."
fi

echo "==> Queue attributes:"
awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

echo "==> SQS demo complete."

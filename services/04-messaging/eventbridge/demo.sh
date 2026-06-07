#!/bin/bash
# ============================================================
# EventBridge Demo
# Purpose: Create event bus, rules, SQS target, and publish events
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUS_NAME="demo-app-events"
RULE_NAME="demo-order-rule"
TARGET_QUEUE="eventbridge-target-queue"

echo "==> Creating custom event bus..."
awslocal events create-event-bus --name "$BUS_NAME" || true
BUS_ARN=$(awslocal events describe-event-bus --name "$BUS_NAME" \
  --output text --query 'Arn')
echo "Event Bus ARN: $BUS_ARN"

echo "==> Creating SQS queue as event target..."
awslocal sqs create-queue --queue-name "$TARGET_QUEUE" || true
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name "$TARGET_QUEUE" --output text --query 'QueueUrl')
QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" \
  --attribute-names QueueArn --output text --query 'Attributes.QueueArn')

echo "==> Creating event rule (filter: source=myapp, detail-type=OrderPlaced)..."
awslocal events put-rule \
  --name "$RULE_NAME" \
  --event-bus-name "$BUS_NAME" \
  --event-pattern '{"source":["myapp.orders"],"detail-type":["OrderPlaced"]}' \
  --state ENABLED || true

echo "==> Adding SQS queue as rule target..."
awslocal events put-targets \
  --rule "$RULE_NAME" \
  --event-bus-name "$BUS_NAME" \
  --targets "[{\"Id\":\"sqs-target\",\"Arn\":\"$QUEUE_ARN\"}]"

echo "==> Publishing events to bus (only OrderPlaced matches rule)..."
awslocal events put-events --entries \
  "[{\"Source\":\"myapp.orders\",\"DetailType\":\"OrderPlaced\",\"Detail\":\"{\\\"orderId\\\":\\\"ORD-100\\\",\\\"amount\\\":59.99}\",\"EventBusName\":\"$BUS_NAME\"},
    {\"Source\":\"myapp.orders\",\"DetailType\":\"OrderShipped\",\"Detail\":\"{\\\"orderId\\\":\\\"ORD-099\\\"}\",\"EventBusName\":\"$BUS_NAME\"}]"

echo "==> Reading matched events from SQS target..."
awslocal sqs receive-message --queue-url "$QUEUE_URL" \
  --max-number-of-messages 5 --wait-time-seconds 2 | python3 -m json.tool

echo "==> Listing rules on bus:"
awslocal events list-rules --event-bus-name "$BUS_NAME"

echo "==> EventBridge demo complete."

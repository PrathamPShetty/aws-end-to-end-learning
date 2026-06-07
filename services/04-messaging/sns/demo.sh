#!/bin/bash
# ============================================================
# SNS (Simple Notification Service) Demo
# Purpose: Create topic, subscribe SQS endpoint, publish messages
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "==> Creating SNS topic..."
TOPIC_ARN=$(awslocal sns create-topic --name demo-notifications \
  --output text --query 'TopicArn') || true
echo "Topic ARN: $TOPIC_ARN"

echo "==> Creating SQS subscriber queue..."
awslocal sqs create-queue --queue-name sns-subscriber-queue || true
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name sns-subscriber-queue --output text --query 'QueueUrl')
QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" \
  --attribute-names QueueArn --output text --query 'Attributes.QueueArn')

echo "==> Subscribing SQS queue to SNS topic..."
SUB_ARN=$(awslocal sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$QUEUE_ARN" \
  --output text --query 'SubscriptionArn')
echo "Subscription ARN: $SUB_ARN"

echo "==> Publishing messages to topic..."
awslocal sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"type":"alert","severity":"high","message":"CPU usage above 90%"}' \
  --subject "System Alert" \
  --message-attributes '{"category":{"DataType":"String","StringValue":"infrastructure"}}'

awslocal sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"type":"info","message":"Deployment completed successfully"}' \
  --subject "Deployment Notice"
echo "Published 2 messages."

echo "==> Reading messages delivered to SQS..."
awslocal sqs receive-message --queue-url "$QUEUE_URL" \
  --max-number-of-messages 5 --wait-time-seconds 1 | python3 -m json.tool

echo "==> Listing subscriptions for topic..."
awslocal sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN"

echo "==> SNS demo complete."

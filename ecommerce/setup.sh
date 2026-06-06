#!/bin/bash
set -e

AWS="awslocal"
REGION="us-east-1"
ACCOUNT="000000000000"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   E-Commerce Order System — Setup        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── IAM ────────────────────────────────────────
echo "▶ IAM: creating Lambda execution role..."
$AWS iam create-role \
  --role-name lambda-exec-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true

$AWS iam attach-role-policy \
  --role-name lambda-exec-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  > /dev/null 2>&1 || true
echo "  ✓ Role: lambda-exec-role"

ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/lambda-exec-role"

# ── S3 ─────────────────────────────────────────
echo ""
echo "▶ S3: creating invoices bucket..."
$AWS s3 mb s3://ecommerce-invoices --region $REGION > /dev/null 2>&1 || true
echo "  ✓ Bucket: ecommerce-invoices"

# ── DynamoDB ────────────────────────────────────
echo ""
echo "▶ DynamoDB: creating tables..."

$AWS dynamodb create-table \
  --table-name Orders \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  > /dev/null 2>&1 || true
echo "  ✓ Table: Orders"

$AWS dynamodb create-table \
  --table-name Inventory \
  --attribute-definitions AttributeName=productId,AttributeType=S \
  --key-schema AttributeName=productId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  > /dev/null 2>&1 || true
echo "  ✓ Table: Inventory"

# Seed inventory
echo "  → Seeding inventory..."
for item in \
  '{"productId":{"S":"laptop"},"name":{"S":"Laptop Pro"},"stock":{"N":"50"},"price":{"N":"999.99"}}' \
  '{"productId":{"S":"phone"},"name":{"S":"SmartPhone X"},"stock":{"N":"100"},"price":{"N":"499.99"}}' \
  '{"productId":{"S":"headphones"},"name":{"S":"Wireless Headphones"},"stock":{"N":"200"},"price":{"N":"79.99"}}'; do
  $AWS dynamodb put-item --table-name Inventory --item "$item" > /dev/null
done
echo "  ✓ Inventory seeded (laptop:50, phone:100, headphones:200)"

# ── SQS ─────────────────────────────────────────
echo ""
echo "▶ SQS: creating queues..."

DLQ_URL=$($AWS sqs create-queue --queue-name ecommerce-dlq --query QueueUrl --output text)
DLQ_ARN=$($AWS sqs get-queue-attributes --queue-url $DLQ_URL --attribute-names QueueArn --query Attributes.QueueArn --output text)
echo "  ✓ Queue: ecommerce-dlq"

REDRIVE="{\"deadLetterTargetArn\":\"${DLQ_ARN}\",\"maxReceiveCount\":\"3\"}"

NOTIF_URL=$($AWS sqs create-queue \
  --queue-name notification-queue \
  --attributes "{\"RedrivePolicy\":\"$(echo $REDRIVE | sed 's/"/\\"/g')\"}" \
  --query QueueUrl --output text 2>/dev/null || \
  $AWS sqs get-queue-url --queue-name notification-queue --query QueueUrl --output text)
NOTIF_ARN=$($AWS sqs get-queue-attributes --queue-url $NOTIF_URL --attribute-names QueueArn --query Attributes.QueueArn --output text)
echo "  ✓ Queue: notification-queue"

INVENTORY_URL=$($AWS sqs create-queue \
  --queue-name inventory-queue \
  --attributes "{\"RedrivePolicy\":\"$(echo $REDRIVE | sed 's/"/\\"/g')\"}" \
  --query QueueUrl --output text 2>/dev/null || \
  $AWS sqs get-queue-url --queue-name inventory-queue --query QueueUrl --output text)
INVENTORY_ARN=$($AWS sqs get-queue-attributes --queue-url $INVENTORY_URL --attribute-names QueueArn --query Attributes.QueueArn --output text)
echo "  ✓ Queue: inventory-queue"

# ── SNS ─────────────────────────────────────────
echo ""
echo "▶ SNS: creating topic and subscriptions..."

TOPIC_ARN=$($AWS sns create-topic --name order-events --query TopicArn --output text)
echo "  ✓ Topic: order-events"

$AWS sns subscribe --topic-arn $TOPIC_ARN --protocol sqs --notification-endpoint $NOTIF_ARN > /dev/null
echo "  ✓ Subscribed: notification-queue"

$AWS sns subscribe --topic-arn $TOPIC_ARN --protocol sqs --notification-endpoint $INVENTORY_ARN > /dev/null
echo "  ✓ Subscribed: inventory-queue"

# ── Kinesis ──────────────────────────────────────
echo ""
echo "▶ Kinesis: creating analytics stream..."
$AWS kinesis create-stream --stream-name order-analytics --shard-count 1 > /dev/null 2>&1 || true
echo "  ✓ Stream: order-analytics"

# ── Lambda ───────────────────────────────────────
echo ""
echo "▶ Lambda: packaging and deploying functions..."

deploy_lambda() {
  local name=$1
  local dir=$2
  local handler=$3
  local env=$4

  cd "$DIR/lambdas/$dir"
  zip -q "${name}.zip" handler.py
  $AWS lambda delete-function --function-name $name > /dev/null 2>&1 || true
  $AWS lambda create-function \
    --function-name $name \
    --runtime python3.11 \
    --role $ROLE_ARN \
    --handler handler.lambda_handler \
    --zip-file fileb://${name}.zip \
    --environment "Variables={$env}" \
    --timeout 30 \
    > /dev/null
  rm -f "${name}.zip"
  cd "$DIR"
  echo "  ✓ Lambda: $name"
}

deploy_lambda "place-order" \
  "place_order" \
  "handler.lambda_handler" \
  "SNS_TOPIC_ARN=${TOPIC_ARN},AWS_DEFAULT_REGION=${REGION}"

deploy_lambda "notification-processor" \
  "notification_processor" \
  "handler.lambda_handler" \
  "INVOICE_BUCKET=ecommerce-invoices,AWS_DEFAULT_REGION=${REGION}"

deploy_lambda "inventory-processor" \
  "inventory_processor" \
  "handler.lambda_handler" \
  "AWS_DEFAULT_REGION=${REGION}"

# ── Event Source Mappings ───────────────────────
echo ""
echo "▶ Lambda Triggers: wiring SQS → Lambda..."

$AWS lambda create-event-source-mapping \
  --function-name notification-processor \
  --event-source-arn $NOTIF_ARN \
  --batch-size 1 > /dev/null 2>&1 || true
echo "  ✓ Trigger: notification-queue → notification-processor"

$AWS lambda create-event-source-mapping \
  --function-name inventory-processor \
  --event-source-arn $INVENTORY_ARN \
  --batch-size 1 > /dev/null 2>&1 || true
echo "  ✓ Trigger: inventory-queue → inventory-processor"

# ── Done ─────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✅  Setup complete!                    ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Place an order:"
echo "  ./scripts/place_order.sh laptop 2 999.99"
echo ""
echo "Check status:"
echo "  ./scripts/check_status.sh"
echo ""

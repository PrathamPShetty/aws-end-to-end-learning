#!/bin/bash

echo ""
echo "══════════════════════════════════════════"
echo "   E-Commerce System — Status Check"
echo "══════════════════════════════════════════"

echo ""
echo "── Orders (DynamoDB) ──────────────────────"
awslocal dynamodb scan --table-name Orders \
  --query 'Items[*].{Order:orderId.S,Customer:customerId.S,Product:product.S,Qty:quantity.N,Status:status.S}' \
  --output table 2>/dev/null || echo "  (no orders yet)"

echo ""
echo "── Inventory (DynamoDB) ───────────────────"
awslocal dynamodb scan --table-name Inventory \
  --query 'Items[*].{Product:productId.S,Name:name.S,Stock:stock.N}' \
  --output table

echo ""
echo "── Invoices (S3) ──────────────────────────"
awslocal s3 ls s3://ecommerce-invoices/invoices/ 2>/dev/null || echo "  (no invoices yet)"

echo ""
echo "── Queues (SQS) ───────────────────────────"
for q in notification-queue inventory-queue ecommerce-dlq; do
  URL=$(awslocal sqs get-queue-url --queue-name $q --query QueueUrl --output text 2>/dev/null)
  COUNT=$(awslocal sqs get-queue-attributes \
    --queue-url $URL \
    --attribute-names ApproximateNumberOfMessages \
    --query 'Attributes.ApproximateNumberOfMessages' \
    --output text 2>/dev/null || echo "?")
  echo "  $q: $COUNT messages"
done

echo ""
echo "── Kinesis Stream ─────────────────────────"
SHARD=$(awslocal kinesis get-shard-iterator \
  --stream-name order-analytics \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query ShardIterator --output text 2>/dev/null)
if [ -n "$SHARD" ]; then
  RECORDS=$(awslocal kinesis get-records --shard-iterator $SHARD \
    --query 'length(Records)' --output text 2>/dev/null || echo 0)
  echo "  order-analytics stream: $RECORDS events recorded"
fi

echo ""
echo "── Lambda Functions ───────────────────────"
awslocal lambda list-functions \
  --query 'Functions[*].{Name:FunctionName,Runtime:Runtime,State:State}' \
  --output table 2>/dev/null

echo ""

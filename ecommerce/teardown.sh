#!/bin/bash
echo "▶ Tearing down all resources..."

awslocal lambda delete-function --function-name place-order 2>/dev/null && echo "  ✓ Lambda: place-order deleted"
awslocal lambda delete-function --function-name notification-processor 2>/dev/null && echo "  ✓ Lambda: notification-processor deleted"
awslocal lambda delete-function --function-name inventory-processor 2>/dev/null && echo "  ✓ Lambda: inventory-processor deleted"

TOPIC_ARN=$(awslocal sns list-topics --query 'Topics[?contains(TopicArn,`order-events`)].TopicArn' --output text 2>/dev/null)
[ -n "$TOPIC_ARN" ] && awslocal sns delete-topic --topic-arn $TOPIC_ARN && echo "  ✓ SNS: order-events deleted"

for q in notification-queue inventory-queue ecommerce-dlq; do
  URL=$(awslocal sqs get-queue-url --queue-name $q --query QueueUrl --output text 2>/dev/null)
  [ -n "$URL" ] && awslocal sqs delete-queue --queue-url $URL && echo "  ✓ SQS: $q deleted"
done

awslocal s3 rm s3://ecommerce-invoices --recursive 2>/dev/null
awslocal s3 rb s3://ecommerce-invoices 2>/dev/null && echo "  ✓ S3: ecommerce-invoices deleted"

awslocal dynamodb delete-table --table-name Orders 2>/dev/null && echo "  ✓ DynamoDB: Orders deleted"
awslocal dynamodb delete-table --table-name Inventory 2>/dev/null && echo "  ✓ DynamoDB: Inventory deleted"

awslocal kinesis delete-stream --stream-name order-analytics 2>/dev/null && echo "  ✓ Kinesis: order-analytics deleted"

echo ""
echo "✅ All resources removed."

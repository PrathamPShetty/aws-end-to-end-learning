#!/bin/bash
# Teardown all AWS resources created by demos
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

A="awslocal"

echo "Tearing down all AWS resources..."

# Lambda
$A lambda list-functions --query 'Functions[].FunctionName' --output text 2>/dev/null | tr '\t' '\n' | while read fn; do
  [ -n "$fn" ] && $A lambda delete-function --function-name "$fn" 2>/dev/null && echo "  deleted lambda: $fn" || true
done

# S3 - empty and delete all buckets
$A s3 ls 2>/dev/null | awk '{print $3}' | while read bucket; do
  [ -n "$bucket" ] && $A s3 rm s3://$bucket --recursive 2>/dev/null; $A s3 rb s3://$bucket 2>/dev/null && echo "  deleted bucket: $bucket" || true
done

# DynamoDB
$A dynamodb list-tables --query 'TableNames[]' --output text 2>/dev/null | tr '\t' '\n' | while read tbl; do
  [ -n "$tbl" ] && $A dynamodb delete-table --table-name "$tbl" 2>/dev/null && echo "  deleted table: $tbl" || true
done

# SQS
$A sqs list-queues --query 'QueueUrls[]' --output text 2>/dev/null | tr '\t' '\n' | while read url; do
  [ -n "$url" ] && $A sqs delete-queue --queue-url "$url" 2>/dev/null && echo "  deleted queue: $url" || true
done

# SNS
$A sns list-topics --query 'Topics[].TopicArn' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  [ -n "$arn" ] && $A sns delete-topic --topic-arn "$arn" 2>/dev/null && echo "  deleted topic: $arn" || true
done

# Kinesis
$A kinesis list-streams --query 'StreamNames[]' --output text 2>/dev/null | tr '\t' '\n' | while read stream; do
  [ -n "$stream" ] && $A kinesis delete-stream --stream-name "$stream" 2>/dev/null && echo "  deleted stream: $stream" || true
done

# KMS - schedule key deletion
$A kms list-keys --query 'Keys[].KeyId' --output text 2>/dev/null | tr '\t' '\n' | while read key; do
  [ -n "$key" ] && $A kms schedule-key-deletion --key-id "$key" --pending-window-in-days 7 2>/dev/null || true
done

# Secrets Manager
$A secretsmanager list-secrets --query 'SecretList[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read secret; do
  [ -n "$secret" ] && $A secretsmanager delete-secret --secret-id "$secret" --force-delete-without-recovery 2>/dev/null && echo "  deleted secret: $secret" || true
done

# StepFunctions
$A stepfunctions list-state-machines --query 'stateMachines[].stateMachineArn' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  [ -n "$arn" ] && $A stepfunctions delete-state-machine --state-machine-arn "$arn" 2>/dev/null && echo "  deleted statemachine: $arn" || true
done

# IAM roles/users/policies
$A iam list-roles --query 'Roles[?starts_with(RoleName, `demo`) == `true`].RoleName' --output text 2>/dev/null | tr '\t' '\n' | while read role; do
  [ -n "$role" ] && $A iam delete-role --role-name "$role" 2>/dev/null || true
done
$A iam list-users --query 'Users[].UserName' --output text 2>/dev/null | tr '\t' '\n' | while read user; do
  [ -n "$user" ] && $A iam delete-user --user-name "$user" 2>/dev/null || true
done

echo ""
echo "✅ Teardown complete."

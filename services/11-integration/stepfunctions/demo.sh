#!/bin/bash
# ============================================================
# Step Functions Demo
# Purpose: Create a state machine, start an execution, poll status
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ACCOUNT="000000000000"
SM_NAME="demo-order-workflow"
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/sfn-demo-role"

echo "==> Creating IAM role for Step Functions..."
awslocal iam create-role --role-name sfn-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true

DEFINITION='{"Comment":"Order workflow","StartAt":"Validate","States":{"Validate":{"Type":"Pass","Result":{"status":"validated"},"ResultPath":"$.validation","Next":"Process"},"Process":{"Type":"Pass","Result":{"status":"paid"},"ResultPath":"$.payment","Next":"Notify"},"Notify":{"Type":"Pass","Result":{"notified":true},"ResultPath":"$.notify","End":true}}}'

echo "==> Creating state machine: $SM_NAME..."
SM_ARN=$(awslocal stepfunctions create-state-machine \
  --name "$SM_NAME" --definition "$DEFINITION" --role-arn "$ROLE_ARN" \
  --output text --query 'stateMachineArn' 2>/dev/null) || \
SM_ARN=$(awslocal stepfunctions list-state-machines \
  --output text --query "stateMachines[?name=='$SM_NAME'].stateMachineArn | [0]")
echo "  ARN: $SM_ARN"

echo "==> Starting execution..."
EXEC_ARN=$(awslocal stepfunctions start-execution \
  --state-machine-arn "$SM_ARN" --name "exec-$(date +%s)" \
  --input '{"orderId":"ORD-42","amount":99.99}' \
  --output text --query 'executionArn')
echo "  Execution: $EXEC_ARN"

echo "==> Execution result..."
awslocal stepfunctions describe-execution \
  --execution-arn "$EXEC_ARN" \
  --query '{Status:status,Output:output}' --output table

echo "==> Execution event types..."
awslocal stepfunctions get-execution-history \
  --execution-arn "$EXEC_ARN" --query 'events[].type' --output table

echo "==> Step Functions demo complete."

#!/bin/bash
# ============================================================
# CloudFormation Demo — Stack lifecycle with S3 + SQS template
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

STACK_NAME="demo-cfn-stack"

TEMPLATE='{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Demo stack: S3 bucket and SQS queue",
  "Resources": {
    "DemoBucket": {
      "Type": "AWS::S3::Bucket",
      "Properties": { "BucketName": "cfn-demo-bucket-01" }
    },
    "DemoQueue": {
      "Type": "AWS::SQS::Queue",
      "Properties": { "QueueName": "cfn-demo-queue" }
    }
  },
  "Outputs": {
    "BucketName": { "Value": { "Ref": "DemoBucket" } },
    "QueueUrl":   { "Value": { "Ref": "DemoQueue"  } }
  }
}'

echo "==> Creating CloudFormation stack: $STACK_NAME..."
awslocal cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body "$TEMPLATE" || true

echo "==> Waiting for stack to reach CREATE_COMPLETE..."
awslocal cloudformation wait stack-create-complete \
  --stack-name "$STACK_NAME" || true

echo "==> Describing stack status..."
awslocal cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[*].{Name:StackName,Status:StackStatus}' \
  --output table

echo "==> Listing stack resources..."
awslocal cloudformation list-stack-resources \
  --stack-name "$STACK_NAME" \
  --query 'StackResourceSummaries[*].{Type:ResourceType,ID:PhysicalResourceId,Status:ResourceStatus}' \
  --output table

echo "==> Fetching stack outputs..."
awslocal cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[*].Outputs[*].{Key:OutputKey,Value:OutputValue}' \
  --output table

echo "==> CloudFormation demo complete."

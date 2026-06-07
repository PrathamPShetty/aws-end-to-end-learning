#!/bin/bash
# ============================================================
# CloudTrail Demo — Trail Creation, Logging, and Event Lookup
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUCKET="demo-cloudtrail-bucket-$$"
TRAIL="demo-trail"

echo "==> Creating S3 bucket for CloudTrail logs: $BUCKET..."
awslocal s3 mb "s3://$BUCKET" || true

echo "==> Applying bucket policy to allow CloudTrail writes..."
ACCOUNT_ID=$(awslocal sts get-caller-identity --query Account --output text)
awslocal s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},
      \"Action\":\"s3:PutObject\",
      \"Resource\":\"arn:aws:s3:::${BUCKET}/AWSLogs/*\"
    }]
  }" || true

echo "==> Creating CloudTrail trail: $TRAIL..."
awslocal cloudtrail create-trail \
  --name "$TRAIL" \
  --s3-bucket-name "$BUCKET" || true

echo "==> Starting logging for trail..."
awslocal cloudtrail start-logging --name "$TRAIL" || true

echo "==> Describing trails..."
awslocal cloudtrail describe-trails \
  --trail-name-list "$TRAIL" \
  --query 'trailList[*].{Name:Name,Bucket:S3BucketName,LoggingEnabled:LogFileValidationEnabled}' \
  --output table

echo "==> Getting trail status..."
awslocal cloudtrail get-trail-status \
  --name "$TRAIL" \
  --query '{IsLogging:IsLogging,LatestDeliveryTime:LatestDeliveryTime}' \
  --output table

echo "==> Looking up recent management events..."
awslocal cloudtrail lookup-events \
  --max-results 5 \
  --query 'Events[*].{EventName:EventName,EventTime:EventTime,Username:Username}' \
  --output table || true

echo "==> CloudTrail demo complete."

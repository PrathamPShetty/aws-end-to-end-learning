#!/bin/bash
# ============================================================
# AWS Config Demo — Recorder, delivery channel, managed rule,
#                   and compliance summary
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUCKET="config-demo-delivery-bucket"
ROLE_ARN="arn:aws:iam::000000000000:role/config-role"

echo "==> Creating S3 bucket for Config delivery..."
awslocal s3 mb "s3://${BUCKET}" || true

echo "==> Putting configuration recorder..."
awslocal configservice put-configuration-recorder \
  --configuration-recorder \
    "name=default,roleARN=${ROLE_ARN},recordingGroup={allSupported=true,includeGlobalResourceTypes=false}"

echo "==> Putting delivery channel..."
awslocal configservice put-delivery-channel \
  --delivery-channel \
    "name=default,s3BucketName=${BUCKET},configSnapshotDeliveryProperties={deliveryFrequency=Six_Hours}" || true

echo "==> Starting configuration recorder..."
awslocal configservice start-configuration-recorder \
  --configuration-recorder-name "default" || true

echo "==> Describing recorder status..."
awslocal configservice describe-configuration-recorder-status \
  --configuration-recorder-names "default" \
  --query 'ConfigurationRecordersStatus[*].{Name:name,Recording:recording}' \
  --output table

echo "==> Creating managed Config rule..."
awslocal configservice put-config-rule \
  --config-rule \
    'ConfigRuleName=s3-public-read-prohibited,Source={Owner=AWS,SourceIdentifier=S3_BUCKET_PUBLIC_READ_PROHIBITED}' || true

echo "==> Listing Config rules..."
awslocal configservice describe-config-rules \
  --query 'ConfigRules[*].{Name:ConfigRuleName,State:ConfigRuleState,Owner:Source.Owner}' \
  --output table

echo "==> Compliance summary by resource type..."
awslocal configservice get-compliance-summary-by-resource-type \
  --query 'ComplianceSummariesByResourceType[*].{Type:ResourceType,Compliant:ComplianceSummary.CompliantResourceCount}' \
  --output table || true

echo "==> AWS Config demo complete."

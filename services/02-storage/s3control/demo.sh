#!/bin/bash
# ============================================================
# AWS S3 Control - S3 Account-Level Management Demo
# Purpose: Manage S3 at account level - access points,
#          batch operations, and public access block settings
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ACCOUNT_ID="000000000000"
BUCKET="demo-s3ctrl-bucket-$$"
ACCESS_POINT="demo-access-point-$$"

echo "==> Creating S3 bucket for access point"
awslocal s3api create-bucket --bucket "$BUCKET" || true

echo ""
echo "==> Setting account-level public access block"
awslocal s3control put-public-access-block \
  --account-id "$ACCOUNT_ID" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "==> Getting account-level public access block config"
awslocal s3control get-public-access-block \
  --account-id "$ACCOUNT_ID" \
  --query 'PublicAccessBlockConfiguration' \
  --output table

echo ""
echo "==> Creating S3 Access Point for the bucket"
awslocal s3control create-access-point \
  --account-id "$ACCOUNT_ID" \
  --name "$ACCESS_POINT" \
  --bucket "$BUCKET"

echo ""
echo "==> Listing access points for bucket"
awslocal s3control list-access-points \
  --account-id "$ACCOUNT_ID" \
  --bucket "$BUCKET" \
  --query 'AccessPointList[].{Name:Name,Bucket:Bucket,NetworkOrigin:NetworkOrigin}' \
  --output table

echo ""
echo "==> Cleanup: deleting access point and bucket"
awslocal s3control delete-access-point \
  --account-id "$ACCOUNT_ID" \
  --name "$ACCESS_POINT" || true
awslocal s3 rb "s3://$BUCKET" --force || true

echo ""
echo "Done. S3 Control demo complete."

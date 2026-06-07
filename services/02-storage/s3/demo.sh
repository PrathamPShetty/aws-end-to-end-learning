#!/bin/bash
# ============================================================
# AWS S3 - Simple Storage Service Demo
# Purpose: Object storage - create buckets, upload/download
#          objects, manage bucket policies and versioning
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUCKET="demo-s3-bucket-$$"

echo "==> Creating S3 bucket: $BUCKET"
awslocal s3api create-bucket --bucket "$BUCKET" || true

echo ""
echo "==> Enabling versioning on bucket"
awslocal s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo ""
echo "==> Uploading objects to bucket"
echo "Hello from LocalStack S3!" | awslocal s3 cp - "s3://$BUCKET/hello.txt"
echo "Version 2 content"        | awslocal s3 cp - "s3://$BUCKET/hello.txt"
echo "Another object"           | awslocal s3 cp - "s3://$BUCKET/notes/readme.txt"

echo ""
echo "==> Listing objects in bucket"
awslocal s3 ls "s3://$BUCKET" --recursive

echo ""
echo "==> Listing object versions (versioning enabled)"
awslocal s3api list-object-versions --bucket "$BUCKET" \
  --query 'Versions[].{Key:Key,VersionId:VersionId,IsLatest:IsLatest}' \
  --output table

echo ""
echo "==> Downloading object"
awslocal s3 cp "s3://$BUCKET/hello.txt" /tmp/s3-hello-$$.txt
echo "Downloaded content: $(cat /tmp/s3-hello-$$.txt)"
rm -f /tmp/s3-hello-$$.txt

echo ""
echo "==> Cleanup: removing bucket and contents"
awslocal s3 rb "s3://$BUCKET" --force

echo ""
echo "Done. S3 demo complete."

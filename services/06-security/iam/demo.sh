#!/bin/bash
# ============================================================
# Service: IAM (Identity and Access Management)
# Purpose: Manage users, roles, and policies for access control
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

USER_NAME="demo-user"
ROLE_NAME="demo-role"
POLICY_NAME="demo-policy"

echo "==> Creating IAM user: $USER_NAME"
awslocal iam create-user --user-name "$USER_NAME" 2>/dev/null || true

echo "==> Attaching inline policy to user"
awslocal iam put-user-policy \
  --user-name "$USER_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:ListBucket"],
      "Resource": "*"
    }]
  }'

echo "==> Listing user policies"
awslocal iam list-user-policies --user-name "$USER_NAME"

echo "==> Creating IAM role with trust policy"
awslocal iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || true

echo "==> Attaching managed policy to role"
awslocal iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

echo "==> Listing attached role policies"
awslocal iam list-attached-role-policies --role-name "$ROLE_NAME"

echo "==> Getting role details"
awslocal iam get-role --role-name "$ROLE_NAME"

echo "==> IAM demo complete."

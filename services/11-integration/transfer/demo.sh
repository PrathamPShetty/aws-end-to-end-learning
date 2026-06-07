#!/bin/bash
# ============================================================
# AWS Transfer Family Demo
# Purpose: Create SFTP server with S3 backend, add managed user
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ACCOUNT="000000000000"
BUCKET="transfer-demo-bucket"
ROLE_NAME="transfer-demo-role"
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/${ROLE_NAME}"
SFTP_USER="demo-sftp-user"

echo "==> Creating S3 bucket as SFTP home directory backend..."
awslocal s3 mb "s3://$BUCKET" 2>/dev/null || true

echo "==> Creating IAM role for Transfer service..."
awslocal iam create-role --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"transfer.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
awslocal iam attach-role-policy --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess" > /dev/null 2>&1 || true
echo "  Role ready: $ROLE_ARN"

echo "==> Creating SFTP server..."
SERVER_ID=$(awslocal transfer create-server \
  --protocols SFTP --endpoint-type PUBLIC \
  --identity-provider-type SERVICE_MANAGED \
  --output text --query 'ServerId' 2>/dev/null) || \
SERVER_ID=$(awslocal transfer list-servers --output text --query 'Servers[0].ServerId')
echo "  Server ID: $SERVER_ID"

echo "==> Adding SFTP user..."
awslocal transfer create-user \
  --server-id "$SERVER_ID" --user-name "$SFTP_USER" \
  --role "$ROLE_ARN" \
  --home-directory "/$BUCKET/home/$SFTP_USER" \
  > /dev/null 2>&1 || true
echo "  User: $SFTP_USER -> s3://$BUCKET/home/$SFTP_USER"

echo "==> Server details..."
awslocal transfer describe-server --server-id "$SERVER_ID" \
  --query 'Server.{Id:ServerId,State:State,Protocols:Protocols}' --output table

echo "==> Users on server..."
awslocal transfer list-users --server-id "$SERVER_ID" \
  --query 'Users[].{UserName:UserName,HomeDirectory:HomeDirectory}' --output table

echo "==> Transfer Family demo complete."

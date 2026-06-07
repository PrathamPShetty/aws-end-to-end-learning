#!/bin/bash
# ============================================================
# SSM Parameter Store Demo — Put, Get, and hierarchy listing
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

APP_PATH="/demo/app"

echo "==> Writing SSM parameters..."
awslocal ssm put-parameter \
  --name "${APP_PATH}/db_host" \
  --value "db.internal.example.com" \
  --type String \
  --overwrite

awslocal ssm put-parameter \
  --name "${APP_PATH}/db_port" \
  --value "5432" \
  --type String \
  --overwrite

awslocal ssm put-parameter \
  --name "${APP_PATH}/db_password" \
  --value "s3cr3t-p@ssw0rd" \
  --type SecureString \
  --overwrite

echo "==> Getting a single parameter (with decryption)..."
awslocal ssm get-parameter \
  --name "${APP_PATH}/db_password" \
  --with-decryption \
  --query 'Parameter.{Name:Name,Value:Value,Type:Type}' \
  --output table

echo "==> Getting parameters by path..."
awslocal ssm get-parameters-by-path \
  --path "$APP_PATH" \
  --with-decryption \
  --query 'Parameters[*].{Name:Name,Value:Value,Type:Type}' \
  --output table

echo "==> Updating a parameter and describing its history..."
awslocal ssm put-parameter \
  --name "${APP_PATH}/db_host" \
  --value "db-replica.internal.example.com" \
  --type String \
  --overwrite

awslocal ssm get-parameter-history \
  --name "${APP_PATH}/db_host" \
  --query 'Parameters[*].{Version:Version,Value:Value}' \
  --output table

echo "==> SSM Parameter Store demo complete."

#!/bin/bash
# ============================================================
# Service: Secrets Manager
# Purpose: Store, retrieve, and rotate application secrets
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

SECRET_NAME="demo/db-credentials"

echo "==> Creating a new secret"
SECRET_ARN=$(awslocal secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Demo database credentials" \
  --secret-string '{"username":"admin","password":"s3cr3tP@ss"}' \
  --query 'ARN' \
  --output text 2>/dev/null) || \
SECRET_ARN=$(awslocal secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --query 'ARN' --output text)
echo "    Secret ARN: $SECRET_ARN"

echo "==> Retrieving the secret value"
awslocal secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query '{Name:Name,SecretString:SecretString}'

echo "==> Updating the secret value"
awslocal secretsmanager put-secret-value \
  --secret-id "$SECRET_NAME" \
  --secret-string '{"username":"admin","password":"n3wP@ssw0rd"}'

echo "==> Listing secret versions"
awslocal secretsmanager list-secret-version-ids \
  --secret-id "$SECRET_NAME" \
  --query 'Versions[*].{VersionId:VersionId,Stages:VersionStages}'

echo "==> Tagging the secret"
awslocal secretsmanager tag-resource \
  --secret-id "$SECRET_NAME" \
  --tags Key=env,Value=demo Key=team,Value=backend

echo "==> Describing secret with tags"
awslocal secretsmanager describe-secret --secret-id "$SECRET_NAME" \
  --query '{Name:Name,Tags:Tags}'

echo "==> Secrets Manager demo complete."

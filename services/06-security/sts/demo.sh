#!/bin/bash
# ============================================================
# Service: STS (Security Token Service)
# Purpose: Issue temporary credentials and assume IAM roles
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ROLE_NAME="demo-sts-role"
SESSION_NAME="demo-session"

echo "==> Getting caller identity"
awslocal sts get-caller-identity

echo "==> Creating an IAM role to assume"
awslocal iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::000000000000:root"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || true

ROLE_ARN=$(awslocal iam get-role \
  --role-name "$ROLE_NAME" \
  --query 'Role.Arn' \
  --output text)
echo "    Role ARN: $ROLE_ARN"

echo "==> Assuming the IAM role"
CREDS=$(awslocal sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --duration-seconds 900)
echo "    AccessKeyId: $(echo "$CREDS" | python3 -c "import sys,json; c=json.load(sys.stdin)['Credentials']; print(c['AccessKeyId'])")"
echo "    Expiration:  $(echo "$CREDS" | python3 -c "import sys,json; c=json.load(sys.stdin)['Credentials']; print(c['Expiration'])")"

echo "==> Getting a session token"
awslocal sts get-session-token \
  --duration-seconds 900 \
  --query 'Credentials.{AccessKeyId:AccessKeyId,Expiration:Expiration}'

echo "==> STS demo complete."

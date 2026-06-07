#!/bin/bash
# ============================================================
# Service: Cognito User Pools (cognito-idp)
# Purpose: Manage user authentication and user directories
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

POOL_NAME="demo-user-pool"
CLIENT_NAME="demo-app-client"
USERNAME="testuser@example.com"
PASSWORD="TempPass@123"

echo "==> Creating Cognito User Pool"
POOL_ID=$(awslocal cognito-idp create-user-pool \
  --pool-name "$POOL_NAME" \
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true}}' \
  --query 'UserPool.Id' \
  --output text)
echo "    Pool ID: $POOL_ID"

echo "==> Creating app client for the pool"
CLIENT_ID=$(awslocal cognito-idp create-user-pool-client \
  --user-pool-id "$POOL_ID" \
  --client-name "$CLIENT_NAME" \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --query 'UserPoolClient.ClientId' \
  --output text)
echo "    Client ID: $CLIENT_ID"

echo "==> Creating (admin) a new user"
awslocal cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" \
  --username "$USERNAME" \
  --temporary-password "$PASSWORD" \
  --message-action SUPPRESS

echo "==> Setting permanent password for the user"
awslocal cognito-idp admin-set-user-password \
  --user-pool-id "$POOL_ID" \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --permanent

echo "==> Getting user details"
awslocal cognito-idp admin-get-user \
  --user-pool-id "$POOL_ID" \
  --username "$USERNAME" \
  --query '{Username:Username,Status:UserStatus,Enabled:Enabled}'

echo "==> Listing users in the pool"
awslocal cognito-idp list-users \
  --user-pool-id "$POOL_ID" \
  --query 'Users[*].{Username:Username,Status:UserStatus}'

echo "==> Cognito User Pools demo complete."

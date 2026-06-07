#!/bin/bash
# ============================================================
# Service: Cognito Identity Pools (Federated Identities)
# Purpose: Grant temporary AWS credentials to app users
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

POOL_NAME="demo-identity-pool"

echo "==> Creating Cognito Identity Pool"
IDENTITY_POOL_ID=$(awslocal cognito-identity create-identity-pool \
  --identity-pool-name "$POOL_NAME" \
  --allow-unauthenticated-identities \
  --query 'IdentityPoolId' \
  --output text)
echo "    Identity Pool ID: $IDENTITY_POOL_ID"

echo "==> Describing the identity pool"
awslocal cognito-identity describe-identity-pool \
  --identity-pool-id "$IDENTITY_POOL_ID" \
  --query '{Name:IdentityPoolName,AllowUnauth:AllowUnauthenticatedIdentities}'

echo "==> Getting an identity ID (unauthenticated)"
IDENTITY_ID=$(awslocal cognito-identity get-id \
  --account-id 000000000000 \
  --identity-pool-id "$IDENTITY_POOL_ID" \
  --query 'IdentityId' \
  --output text)
echo "    Identity ID: $IDENTITY_ID"

echo "==> Getting credentials for the identity"
awslocal cognito-identity get-credentials-for-identity \
  --identity-id "$IDENTITY_ID" \
  --query 'Credentials.{AccessKeyId:AccessKeyId,Expiration:Expiration}'

echo "==> Updating identity pool to disable unauthenticated access"
awslocal cognito-identity update-identity-pool \
  --identity-pool-id "$IDENTITY_POOL_ID" \
  --identity-pool-name "$POOL_NAME" \
  --no-allow-unauthenticated-identities \
  --query '{Name:IdentityPoolName,AllowUnauth:AllowUnauthenticatedIdentities}'

echo "==> Cognito Identity Pools demo complete."

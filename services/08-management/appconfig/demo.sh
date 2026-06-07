#!/bin/bash
# ============================================================
# AppConfig Demo — Application, environment, hosted config,
#                  deployment strategy, and deployment
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "==> Creating AppConfig application..."
APP_ID=$(awslocal appconfig create-application \
  --name "demo-app" --description "Demo application" \
  --query 'Id' --output text)
echo "    Application ID: $APP_ID"

echo "==> Creating environment..."
ENV_ID=$(awslocal appconfig create-environment \
  --application-id "$APP_ID" --name "demo-env" \
  --query 'Id' --output text)

echo "==> Creating hosted configuration profile..."
PROFILE_ID=$(awslocal appconfig create-configuration-profile \
  --application-id "$APP_ID" --name "demo-profile" \
  --location-uri "hosted" --query 'Id' --output text)

echo "==> Uploading hosted configuration version..."
VERSION=$(awslocal appconfig create-hosted-configuration-version \
  --application-id "$APP_ID" \
  --configuration-profile-id "$PROFILE_ID" \
  --content '{"feature_dark_mode":true,"max_retries":3}' \
  --content-type "application/json" \
  --query 'VersionNumber' --output text)
echo "    Config version: $VERSION"

echo "==> Creating instant deployment strategy..."
STRATEGY_ID=$(awslocal appconfig create-deployment-strategy \
  --name "demo-instant" --deployment-duration-in-minutes 0 \
  --growth-factor 100 --replicate-to "NONE" \
  --query 'Id' --output text)

echo "==> Starting deployment..."
awslocal appconfig start-deployment \
  --application-id "$APP_ID" --environment-id "$ENV_ID" \
  --deployment-strategy-id "$STRATEGY_ID" \
  --configuration-profile-id "$PROFILE_ID" \
  --configuration-version "$VERSION" \
  --query '{State:State,PercentageComplete:PercentageComplete}' \
  --output table || true

echo "==> Listing configuration profiles..."
awslocal appconfig list-configuration-profiles \
  --application-id "$APP_ID" \
  --query 'Items[*].{Name:Name,Id:Id,LocationUri:LocationUri}' \
  --output table

echo "==> AppConfig demo complete."

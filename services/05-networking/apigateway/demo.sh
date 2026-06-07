#!/bin/bash
# =============================================================
# Service: API Gateway (REST)
# Purpose: Create REST API, resource, method, integration, deploy
# =============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo ">>> [API Gateway] Creating REST API"
API_ID=$(awslocal apigateway create-rest-api \
  --name "demo-api" \
  --query 'id' --output text)
echo "API ID: $API_ID"

echo ">>> [API Gateway] Getting root resource"
ROOT_ID=$(awslocal apigateway get-resources \
  --rest-api-id "$API_ID" \
  --query 'items[0].id' --output text)

echo ">>> [API Gateway] Creating /hello resource"
RESOURCE_ID=$(awslocal apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part "hello" \
  --query 'id' --output text)
echo "Resource ID: $RESOURCE_ID"

echo ">>> [API Gateway] Adding GET method to /hello"
awslocal apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --authorization-type NONE

echo ">>> [API Gateway] Adding MOCK integration"
awslocal apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}'

echo ">>> [API Gateway] Deploying to 'dev' stage"
awslocal apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name dev

echo ">>> [API Gateway] Listing APIs"
awslocal apigateway get-rest-apis --output table

echo "Endpoint: http://localhost:4566/restapis/$API_ID/dev/_user_request_/hello"
echo "Done."

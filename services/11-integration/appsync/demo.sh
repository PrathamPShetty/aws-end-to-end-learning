#!/bin/bash
# ============================================================
# AppSync Demo
# Purpose: Create GraphQL API, schema, data source, and resolver
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ACCOUNT="000000000000"
API_NAME="demo-todo-api"
ROLE_NAME="appsync-demo-role"
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/${ROLE_NAME}"
TABLE_NAME="TodoTable"

echo "==> Creating DynamoDB table as data source..."
awslocal dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  > /dev/null 2>&1 || true
echo "  Table: $TABLE_NAME"

echo "==> Creating IAM role for AppSync..."
awslocal iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"appsync.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
awslocal iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" \
  > /dev/null 2>&1 || true
echo "  IAM role ready"

echo "==> Creating AppSync GraphQL API..."
API_ID=$(awslocal appsync create-graphql-api \
  --name "$API_NAME" \
  --authentication-type API_KEY \
  --output text --query 'graphqlApi.apiId') 2>/dev/null || \
API_ID=$(awslocal appsync list-graphql-apis \
  --output text --query "graphqlApis[?name=='$API_NAME'].apiId | [0]")
echo "  API ID: $API_ID"

echo "==> Creating API key..."
KEY_ID=$(awslocal appsync create-api-key \
  --api-id "$API_ID" \
  --description "Demo key" \
  --output text --query 'apiKey.id') 2>/dev/null || true
echo "  API Key ID: $KEY_ID"

echo "==> Uploading GraphQL schema..."
SCHEMA='type Todo {
  id: ID!
  title: String!
  done: Boolean
}
type Query {
  getTodo(id: ID!): Todo
  listTodos: [Todo]
}
type Mutation {
  createTodo(id: ID!, title: String!): Todo
}
schema { query: Query mutation: Mutation }'
awslocal appsync start-schema-creation \
  --api-id "$API_ID" \
  --definition "$(echo "$SCHEMA" | base64)" \
  > /dev/null 2>&1 || true
echo "  Schema submitted"

echo "==> Attaching DynamoDB data source..."
awslocal appsync create-data-source \
  --api-id "$API_ID" \
  --name "TodoDynamoDB" \
  --type AMAZON_DYNAMODB \
  --service-role-arn "$ROLE_ARN" \
  --dynamodb-config "tableName=${TABLE_NAME},awsRegion=us-east-1" \
  > /dev/null 2>&1 || true
echo "  Data source attached"

echo "==> Listing GraphQL APIs..."
awslocal appsync list-graphql-apis \
  --query 'graphqlApis[].{Name:name,ApiId:apiId,AuthType:authenticationType}' \
  --output table

echo "==> Listing data sources..."
awslocal appsync list-data-sources \
  --api-id "$API_ID" \
  --query 'dataSources[].{Name:name,Type:type}' \
  --output table

echo "==> AppSync demo complete."

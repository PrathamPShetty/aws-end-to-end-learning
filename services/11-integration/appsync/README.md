# AWS AppSync

## What is it?
AWS AppSync is a fully managed GraphQL API service that connects your frontend applications to multiple backend data sources — DynamoDB, Lambda, RDS, HTTP endpoints, and more — through a single, strongly typed GraphQL schema. It handles real-time data synchronisation via GraphQL subscriptions (WebSocket) and provides offline data access for mobile apps using conflict-resolution strategies. AppSync removes the need to build and maintain a custom GraphQL server, handling schema validation, request/response mapping, and API key or Cognito authentication out of the box. It is the right choice for any application that needs a flexible, client-driven query interface over heterogeneous data sources.

## Key Concepts
- **GraphQL API** — the top-level AppSync resource identified by an `apiId`; it owns the schema, data sources, resolvers, and API keys.
- **Schema** — the SDL (Schema Definition Language) file that defines your types, queries, mutations, and subscriptions; uploaded via `start-schema-creation`.
- **Data Source** — a named backend connection (DynamoDB table, Lambda function, HTTP endpoint, RDS, or NONE) that resolvers call to fetch or mutate data.
- **Resolver** — maps a GraphQL field (query/mutation/subscription) to a data source; uses VTL (Velocity Template Language) or JavaScript to transform the request and response.
- **API Key** — a simple shared secret for authenticating API callers; AppSync also supports Amazon Cognito User Pools, IAM, and OIDC authentication.
- **Subscription** — a GraphQL real-time feature that pushes mutations to connected clients over WebSocket; defined in the schema with the `@aws_subscribe` directive.

## When to Use
- **Mobile and web frontends** — let React, Vue, or mobile clients query exactly the fields they need from multiple backends in a single request, reducing over-fetching and round trips.
- **Real-time collaboration apps** — use GraphQL subscriptions to push live updates (chat messages, document edits, dashboard metrics) to all connected clients the moment data changes.
- **Unified data layer** — aggregate data from DynamoDB, a REST API, and a Lambda function behind one GraphQL schema so clients never need to know which backend owns which data.
- **Offline-first mobile apps** — use the AWS Amplify DataStore with AppSync conflict resolution so apps sync automatically when connectivity is restored.

## CLI Quick Reference (awslocal)

### Create a GraphQL API
```bash
awslocal appsync create-graphql-api \
  --name todo-api \
  --authentication-type API_KEY
```

### List GraphQL APIs
```bash
awslocal appsync list-graphql-apis \
  --query 'graphqlApis[].{Name:name,ApiId:apiId,AuthType:authenticationType}' \
  --output table
```

### Get / describe an API
```bash
awslocal appsync get-graphql-api \
  --api-id abc123defg456
```

### Create an API key
```bash
awslocal appsync create-api-key \
  --api-id abc123defg456 \
  --description "Dev key"
```

### List API keys
```bash
awslocal appsync list-api-keys --api-id abc123defg456
```

### Upload a schema
```bash
awslocal appsync start-schema-creation \
  --api-id abc123defg456 \
  --definition "$(base64 < schema.graphql)"
```

### Create a data source
```bash
awslocal appsync create-data-source \
  --api-id abc123defg456 \
  --name TodoDynamoDB \
  --type AMAZON_DYNAMODB \
  --service-role-arn arn:aws:iam::000000000000:role/appsync-role \
  --dynamodb-config "tableName=TodoTable,awsRegion=us-east-1"
```

### List data sources
```bash
awslocal appsync list-data-sources --api-id abc123defg456 \
  --query 'dataSources[].{Name:name,Type:type}' --output table
```

### Delete an API
```bash
awslocal appsync delete-graphql-api --api-id abc123defg456
```

## Example Walkthrough

1. **Create the DynamoDB table** that will back the GraphQL data source.
   ```bash
   awslocal dynamodb create-table \
     --table-name TodoTable \
     --attribute-definitions AttributeName=id,AttributeType=S \
     --key-schema AttributeName=id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. **Create an IAM role** that AppSync can assume to call DynamoDB.
   ```bash
   awslocal iam create-role --role-name appsync-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"appsync.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   awslocal iam attach-role-policy --role-name appsync-role \
     --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
   ```

3. **Create the GraphQL API** — returns an `apiId` needed for all subsequent commands.
   ```bash
   API_ID=$(awslocal appsync create-graphql-api \
     --name todo-api \
     --authentication-type API_KEY \
     --output text --query 'graphqlApi.apiId')
   echo "API ID: $API_ID"
   ```

4. **Create an API key** — required when `authentication-type` is `API_KEY`.
   ```bash
   KEY_ID=$(awslocal appsync create-api-key \
     --api-id "$API_ID" \
     --description "Dev key" \
     --output text --query 'apiKey.id')
   echo "API key: $KEY_ID"
   ```

5. **Upload the GraphQL schema** — defines `Todo` type, `Query`, and `Mutation`.
   ```bash
   SCHEMA='type Todo{id:ID! title:String! done:Boolean} type Query{getTodo(id:ID!):Todo listTodos:[Todo]} type Mutation{createTodo(id:ID!,title:String!):Todo} schema{query:Query mutation:Mutation}'
   awslocal appsync start-schema-creation \
     --api-id "$API_ID" \
     --definition "$(printf '%s' "$SCHEMA" | base64)"
   echo "Schema uploaded"
   ```

6. **Attach the DynamoDB data source** — connects the API to the TodoTable.
   ```bash
   awslocal appsync create-data-source \
     --api-id "$API_ID" \
     --name TodoDynamoDB \
     --type AMAZON_DYNAMODB \
     --service-role-arn arn:aws:iam::000000000000:role/appsync-role \
     --dynamodb-config "tableName=TodoTable,awsRegion=us-east-1"
   ```

7. **List data sources and API keys** — confirm everything is wired correctly.
   ```bash
   awslocal appsync list-data-sources --api-id "$API_ID" \
     --query 'dataSources[].{Name:name,Type:type}' --output table
   awslocal appsync list-api-keys --api-id "$API_ID" \
     --query 'apiKeys[].{Id:id,Description:description}' --output table
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--name` | Display name for the API or data source | `todo-api` |
| `--authentication-type` | Primary auth method for the API | `API_KEY`, `AWS_IAM`, `AMAZON_COGNITO_USER_POOLS`, `OPENID_CONNECT` |
| `--api-id` | Unique identifier of the GraphQL API | `abc123defg456` |
| `--definition` | Base64-encoded SDL schema string | `$(base64 < schema.graphql)` |
| `--type` | Data source backend type | `AMAZON_DYNAMODB`, `AWS_LAMBDA`, `HTTP`, `NONE`, `RELATIONAL_DATABASE` |
| `--service-role-arn` | IAM role AppSync assumes to access the data source | `arn:aws:iam::000000000000:role/appsync-role` |
| `--dynamodb-config` | DynamoDB-specific settings: table name and region | `tableName=TodoTable,awsRegion=us-east-1` |
| `--lambda-config` | Lambda-specific settings: function ARN | `lambdaFunctionArn=arn:aws:lambda:...` |
| `--description` | Human-readable label for an API key | `"Dev key"` |
| `--expires` | Unix timestamp for API key expiry | `1893456000` |
| `--additional-authentication-providers` | Secondary auth methods (multiple allowed) | `[{"authenticationType":"AWS_IAM"}]` |

## How to Run the Demo

```bash
cd services/11-integration/appsync
bash demo.sh
```

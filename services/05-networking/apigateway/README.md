# Amazon API Gateway

## What is it?
Amazon API Gateway is a fully managed service for creating, publishing, securing, and monitoring REST, HTTP, and WebSocket APIs at any scale. It acts as the "front door" for your backend services — routing HTTP requests to AWS Lambda functions, EC2 instances, or any publicly accessible HTTP endpoint. API Gateway handles traffic management, authorization and access control, throttling, monitoring, and API versioning so you can focus on writing business logic. Use it whenever you need to expose a backend service over a standard HTTP/HTTPS interface.

## Key Concepts
- **REST API** — The classic API Gateway offering; supports full request/response transformation, usage plans, API keys, and fine-grained method-level configuration.
- **Resource** — A URL path segment in your API (e.g., `/users`, `/users/{id}`). Resources are organized in a tree rooted at `/`.
- **Method** — An HTTP verb (GET, POST, PUT, DELETE, etc.) attached to a resource that defines how a request is handled.
- **Integration** — The backend the method connects to: `MOCK` (static response), `AWS_PROXY` (Lambda proxy), `HTTP` (external URL), or `AWS` (direct AWS service call).
- **Stage** — A named snapshot/deployment of your API (e.g., `dev`, `staging`, `prod`). Each stage gets its own invoke URL.
- **Deployment** — The act of publishing the current API configuration to a stage, making changes live.

## When to Use
- **Serverless REST APIs** — Pair with AWS Lambda to build fully serverless backends where API Gateway handles routing and Lambda handles logic.
- **Microservice facade** — Place a single API Gateway in front of multiple backend microservices to present a unified URL surface to clients.
- **Prototyping with mock responses** — Use MOCK integrations to return static JSON responses before backend logic is built, enabling frontend development in parallel.
- **Rate limiting and API key management** — Enforce per-client throttling and usage quotas without modifying backend code.

## CLI Quick Reference (awslocal)

### API Operations
| Operation | Command |
|-----------|---------|
| Create REST API | `awslocal apigateway create-rest-api --name "my-api"` |
| List REST APIs | `awslocal apigateway get-rest-apis` |
| Get API details | `awslocal apigateway get-rest-api --rest-api-id <api-id>` |
| Delete REST API | `awslocal apigateway delete-rest-api --rest-api-id <api-id>` |

### Resource & Method Operations
```bash
# List resources (get root resource ID)
awslocal apigateway get-resources --rest-api-id <api-id>

# Create a resource at /hello
awslocal apigateway create-resource \
  --rest-api-id <api-id> \
  --parent-id <root-resource-id> \
  --path-part "hello"

# Add GET method (no auth)
awslocal apigateway put-method \
  --rest-api-id <api-id> \
  --resource-id <resource-id> \
  --http-method GET \
  --authorization-type NONE

# Deploy to a stage
awslocal apigateway create-deployment \
  --rest-api-id <api-id> \
  --stage-name dev
```

## Example Walkthrough

1. **Create a new REST API**
   ```bash
   API_ID=$(awslocal apigateway create-rest-api \
     --name "demo-api" \
     --query 'id' --output text)
   echo "API ID: $API_ID"
   ```
   Registers a new REST API and captures its unique ID for all subsequent commands.

2. **Get the root resource ID (`/`)**
   ```bash
   ROOT_ID=$(awslocal apigateway get-resources \
     --rest-api-id "$API_ID" \
     --query 'items[0].id' --output text)
   echo "Root resource ID: $ROOT_ID"
   ```
   Every API has a pre-created root `/` resource; child resources are nested under it.

3. **Create a `/hello` resource under root**
   ```bash
   RESOURCE_ID=$(awslocal apigateway create-resource \
     --rest-api-id "$API_ID" \
     --parent-id "$ROOT_ID" \
     --path-part "hello" \
     --query 'id' --output text)
   echo "Resource ID: $RESOURCE_ID"
   ```
   Adds the `/hello` path segment to the API's resource tree.

4. **Attach a GET method to `/hello`**
   ```bash
   awslocal apigateway put-method \
     --rest-api-id "$API_ID" \
     --resource-id "$RESOURCE_ID" \
     --http-method GET \
     --authorization-type NONE
   ```
   Declares that `GET /hello` is a valid operation with no authentication required.

5. **Configure a MOCK integration returning HTTP 200**
   ```bash
   awslocal apigateway put-integration \
     --rest-api-id "$API_ID" \
     --resource-id "$RESOURCE_ID" \
     --http-method GET \
     --type MOCK \
     --request-templates '{"application/json": "{\"statusCode\": 200}"}'
   ```
   Sets up a mock backend that immediately returns a 200 status without calling any real service.

6. **Deploy the API to the `dev` stage**
   ```bash
   awslocal apigateway create-deployment \
     --rest-api-id "$API_ID" \
     --stage-name dev
   ```
   Publishes the current API configuration and makes it callable at the `dev` stage URL.

7. **Invoke the endpoint**
   ```bash
   curl http://localhost:4566/restapis/$API_ID/dev/_user_request_/hello
   ```
   Sends a real HTTP request to the deployed API through LocalStack.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--name` | Human-readable name for the REST API |
| `--rest-api-id` | The unique ID of the API (returned at creation) |
| `--parent-id` | ID of the parent resource when creating a child resource |
| `--path-part` | URL path segment for the new resource (e.g., `hello`, `{id}`) |
| `--http-method` | HTTP verb: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `ANY` |
| `--authorization-type` | `NONE`, `AWS_IAM`, `COGNITO_USER_POOLS`, or `CUSTOM` |
| `--type` (integration) | Integration backend: `MOCK`, `AWS`, `AWS_PROXY`, `HTTP`, `HTTP_PROXY` |
| `--stage-name` | Name of the deployment stage (e.g., `dev`, `prod`) |
| `--request-templates` | Maps content types to integration request templates (JSON transform) |

## How to Run the Demo
```bash
cd services/05-networking/apigateway
bash demo.sh
```

# AWS Lambda

## What is it?
AWS Lambda is a serverless compute service that runs your code in response to events without requiring you to provision or manage servers. You upload a function (written in Python, Node.js, Java, Go, etc.), define what triggers it (an HTTP request, a file upload, a message in a queue), and AWS handles everything else — scaling, patching, and availability. Lambda charges only for the compute time your code actually uses, measured in milliseconds. It is the go-to choice whenever you want to run short-lived, event-driven logic without operating infrastructure.

## Key Concepts
- **Function** — the unit of deployment: your code plus its runtime, handler, and configuration.
- **Handler** — the entry-point function Lambda calls (e.g. `handler.lambda_handler`).
- **Runtime** — the language environment that executes your code (e.g. `python3.11`, `nodejs20.x`).
- **Trigger / Event Source** — the AWS service or API call that invokes the function (API Gateway, S3, SQS, EventBridge, etc.).
- **Execution Role** — an IAM role that grants the function permission to call other AWS services.
- **Reserved Concurrency** — the maximum number of simultaneous executions reserved for a single function.

## When to Use
- **API backends** — pair Lambda with API Gateway to build REST or HTTP APIs that scale to zero when idle.
- **Event processing** — process S3 uploads, DynamoDB streams, SQS messages, or Kinesis records automatically as they arrive.
- **Scheduled jobs** — replace cron servers with an EventBridge rule that triggers a Lambda on a schedule (e.g. nightly report generation).
- **Glue code / orchestration** — run lightweight transformation, validation, or routing logic between other AWS services without a dedicated server.

## CLI Quick Reference (awslocal)

### Create
```bash
# Package code
zip fn.zip handler.py

# Create function
awslocal lambda create-function \
  --function-name my-function \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/lambda-exec-role \
  --handler handler.lambda_handler \
  --zip-file fileb://fn.zip \
  --timeout 30 \
  --memory-size 128
```

### List
```bash
awslocal lambda list-functions \
  --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Timeout:Timeout}' \
  --output table
```

### Get / Describe
```bash
awslocal lambda get-function --function-name my-function
awslocal lambda get-function-configuration --function-name my-function
```

### Invoke
```bash
awslocal lambda invoke \
  --function-name my-function \
  --payload '{"name":"world"}' \
  --cli-binary-format raw-in-base64-out \
  response.json
cat response.json
```

### Update (code)
```bash
zip fn.zip handler.py
awslocal lambda update-function-code \
  --function-name my-function \
  --zip-file fileb://fn.zip
```

### Update (configuration)
```bash
awslocal lambda update-function-configuration \
  --function-name my-function \
  --timeout 60 \
  --memory-size 256 \
  --environment "Variables={ENV=prod,LOG_LEVEL=INFO}"
```

### Delete
```bash
awslocal lambda delete-function --function-name my-function
```

## Example Walkthrough

1. **Create an IAM execution role** — Lambda needs a role to assume when it runs.
   ```bash
   awslocal iam create-role \
     --role-name lambda-exec-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Write and package the handler** — create a Python file and zip it.
   ```bash
   cat > handler.py <<'EOF'
   import json
   def lambda_handler(event, context):
       name = event.get("name", "world")
       return {"statusCode": 200, "body": json.dumps({"message": f"Hello, {name}!"})}
   EOF
   zip fn.zip handler.py
   ```

3. **Create the Lambda function** — deploy the zip to LocalStack.
   ```bash
   awslocal lambda create-function \
     --function-name hello-fn \
     --runtime python3.11 \
     --role arn:aws:iam::000000000000:role/lambda-exec-role \
     --handler handler.lambda_handler \
     --zip-file fileb://fn.zip
   ```

4. **Invoke the function** — send a test payload and capture the response.
   ```bash
   awslocal lambda invoke \
     --function-name hello-fn \
     --payload '{"name":"LocalStack"}' \
     --cli-binary-format raw-in-base64-out \
     response.json
   cat response.json
   # {"statusCode": 200, "body": "{\"message\": \"Hello, LocalStack!\"}"}
   ```

5. **Set reserved concurrency** — cap how many instances run at the same time.
   ```bash
   awslocal lambda put-function-concurrency \
     --function-name hello-fn \
     --reserved-concurrent-executions 5
   ```

6. **Update the code** — redeploy after making a code change.
   ```bash
   # Edit handler.py, then:
   zip fn.zip handler.py
   awslocal lambda update-function-code \
     --function-name hello-fn \
     --zip-file fileb://fn.zip
   ```

7. **Delete the function** — clean up when done.
   ```bash
   awslocal lambda delete-function --function-name hello-fn
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--function-name` | Name or ARN of the function | `hello-fn` |
| `--runtime` | Language runtime | `python3.11`, `nodejs20.x`, `java21` |
| `--handler` | `<file>.<function>` entry point | `handler.lambda_handler` |
| `--zip-file` | Local zip to upload (`fileb://`) | `fileb://fn.zip` |
| `--timeout` | Max execution time in seconds (default 3, max 900) | `30` |
| `--memory-size` | MB of RAM (128–10240) | `256` |
| `--environment` | Key-value environment variables | `Variables={KEY=val}` |
| `--role` | IAM execution role ARN | `arn:aws:iam::000000000000:role/...` |
| `--payload` | JSON event passed to the handler on invocation | `'{"key":"value"}'` |
| `--cli-binary-format` | Required when passing raw JSON payload | `raw-in-base64-out` |
| `--reserved-concurrent-executions` | Max simultaneous invocations | `10` |

## How to Run the Demo

```bash
cd services/01-compute/lambda
bash demo.sh
```

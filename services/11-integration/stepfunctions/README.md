# AWS Step Functions

## What is it?
AWS Step Functions is a fully managed serverless orchestration service that lets you coordinate multiple AWS services into visual, auditable workflows called state machines. You define each step of your workflow in Amazon States Language (a JSON-based spec), and Step Functions handles retries, error handling, parallel branching, and state passing between steps automatically. It is the right choice any time you need to chain Lambda functions, ECS tasks, or other service integrations into a reliable multi-step process. Its built-in execution history makes debugging long-running workflows straightforward.

## Key Concepts
- **State Machine** — the workflow definition, written in Amazon States Language, describing all states and transitions.
- **State** — a single step in a workflow; types include Task, Pass, Choice, Wait, Parallel, Map, Succeed, and Fail.
- **Execution** — a single run of a state machine, carrying its own input, output, and event history.
- **Task State** — a state that performs work by calling a Lambda function, an ECS task, an AWS SDK API, or another service integration.
- **Amazon States Language (ASL)** — the JSON dialect used to define state machines, including retries, error catchers, and data-flow expressions.
- **Express vs. Standard Workflows** — Standard workflows run up to one year and guarantee exactly-once execution; Express workflows run up to five minutes and are optimised for high-throughput, at-least-once scenarios.

## When to Use
- **Order and payment pipelines** — orchestrate validation, payment processing, inventory reservation, and notification steps with automatic retries on transient failures.
- **Data transformation pipelines** — fan out with Parallel or Map states to process files or records concurrently, then aggregate results.
- **Human-approval workflows** — pause execution with a Wait state and a callback token until an external system (e.g., a manager's approval email) resumes the flow.
- **Microservice choreography** — replace ad-hoc Lambda-to-Lambda calls with a versioned, observable state machine that shows exactly which step failed and why.

## CLI Quick Reference (awslocal)

### Create
```bash
awslocal stepfunctions create-state-machine \
  --name "order-workflow" \
  --definition file://definition.json \
  --role-arn arn:aws:iam::000000000000:role/sfn-exec-role \
  --type STANDARD
```

### List
```bash
awslocal stepfunctions list-state-machines \
  --query 'stateMachines[].{Name:name,Arn:stateMachineArn}' \
  --output table
```

### Get / Describe
```bash
awslocal stepfunctions describe-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:order-workflow
```

### Start Execution
```bash
awslocal stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:order-workflow \
  --name "exec-001" \
  --input '{"orderId":"ORD-42","amount":99.99}'
```

### Describe Execution
```bash
awslocal stepfunctions describe-execution \
  --execution-arn arn:aws:states:us-east-1:000000000000:execution:order-workflow:exec-001
```

### Get Execution History
```bash
awslocal stepfunctions get-execution-history \
  --execution-arn arn:aws:states:us-east-1:000000000000:execution:order-workflow:exec-001 \
  --query 'events[].{Type:type,Timestamp:timestamp}' \
  --output table
```

### Update
```bash
awslocal stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:order-workflow \
  --definition file://definition-v2.json
```

### Delete
```bash
awslocal stepfunctions delete-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:order-workflow
```

## Example Walkthrough

1. **Create an IAM role for Step Functions** — the service needs permission to invoke Lambda and other resources.
   ```bash
   awslocal iam create-role \
     --role-name sfn-exec-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Write the state machine definition** — a three-step Pass workflow that simulates validate → process → notify.
   ```bash
   cat > definition.json <<'EOF'
   {
     "Comment": "Order workflow",
     "StartAt": "Validate",
     "States": {
       "Validate": {"Type":"Pass","Result":{"status":"validated"},"ResultPath":"$.validation","Next":"Process"},
       "Process":  {"Type":"Pass","Result":{"status":"paid"},     "ResultPath":"$.payment",  "Next":"Notify"},
       "Notify":   {"Type":"Pass","Result":{"notified":true},     "ResultPath":"$.notify",   "End":true}
     }
   }
   EOF
   ```

3. **Create the state machine** — register the definition with LocalStack.
   ```bash
   SM_ARN=$(awslocal stepfunctions create-state-machine \
     --name "order-workflow" \
     --definition file://definition.json \
     --role-arn arn:aws:iam::000000000000:role/sfn-exec-role \
     --output text --query 'stateMachineArn')
   echo "State machine ARN: $SM_ARN"
   ```

4. **Start an execution** — run the workflow with a sample order payload.
   ```bash
   EXEC_ARN=$(awslocal stepfunctions start-execution \
     --state-machine-arn "$SM_ARN" \
     --name "exec-$(date +%s)" \
     --input '{"orderId":"ORD-42","amount":99.99}' \
     --output text --query 'executionArn')
   echo "Execution ARN: $EXEC_ARN"
   ```

5. **Check execution status** — confirm the workflow completed successfully.
   ```bash
   awslocal stepfunctions describe-execution \
     --execution-arn "$EXEC_ARN" \
     --query '{Status:status,Output:output}' \
     --output table
   ```

6. **View the event history** — see every state transition recorded for auditing.
   ```bash
   awslocal stepfunctions get-execution-history \
     --execution-arn "$EXEC_ARN" \
     --query 'events[].type' \
     --output table
   ```

7. **Clean up** — delete the state machine when done.
   ```bash
   awslocal stepfunctions delete-state-machine --state-machine-arn "$SM_ARN"
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--name` | Unique name for the state machine or execution | `order-workflow` |
| `--definition` | ASL JSON as a string or `file://` path | `file://definition.json` |
| `--role-arn` | IAM role Step Functions assumes to run tasks | `arn:aws:iam::000000000000:role/sfn-exec-role` |
| `--type` | Workflow type: `STANDARD` (long-running) or `EXPRESS` (high-throughput) | `STANDARD` |
| `--input` | JSON payload passed to the first state | `'{"orderId":"ORD-42"}'` |
| `--state-machine-arn` | Full ARN of the target state machine | `arn:aws:states:us-east-1:000000000000:stateMachine:...` |
| `--execution-arn` | Full ARN of a specific execution | `arn:aws:states:us-east-1:000000000000:execution:...` |
| `--max-results` | Limit number of results returned by list commands | `20` |
| `--reverse-order` | Return execution history in reverse chronological order | (flag only) |
| `--logging-configuration` | Send execution logs to CloudWatch Logs | `level=ALL,destinations=[...]` |

## How to Run the Demo

```bash
cd services/11-integration/stepfunctions
bash demo.sh
```

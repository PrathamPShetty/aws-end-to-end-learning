# Amazon SWF (Simple Workflow Service)

## What is it?
Amazon Simple Workflow Service (SWF) is a fully managed workflow orchestration service that coordinates work across distributed application components. You define workflows as a combination of Activities (discrete units of work, typically run by application workers) and a Decider (a process that polls for events and decides the next step based on the execution history). SWF tracks every event in a durable, append-only history so you never lose progress, even if individual workers crash and restart. It is the right choice for long-running, stateful workflows that require fine-grained control over task routing, timeouts, and retry logic; for new projects, AWS Step Functions provides a higher-level, code-free alternative.

## Key Concepts
- **Domain** — a logical namespace that groups all workflow types, activity types, and executions; workflows in different domains cannot interact.
- **Workflow Type** — a versioned blueprint for a workflow, registered within a domain; defines default timeouts and task list.
- **Activity Type** — a versioned blueprint for a single unit of work (e.g., "charge credit card"); workers poll a task list to receive activity tasks.
- **Workflow Execution** — a running instance of a workflow type, identified by a `workflowId` and `runId`; holds a complete, ordered event history.
- **Task List** — a named queue that deciders and activity workers poll; routing activities to specific task lists lets you target work to particular worker pools.
- **Decider** — an application process that polls for decision tasks, reads the execution history, and returns decisions (ScheduleActivityTask, CompleteWorkflowExecution, FailWorkflowExecution, etc.).

## When to Use
- **Order fulfillment pipelines** — coordinate payment, inventory reservation, and shipping steps across separate services with each step retried independently on failure.
- **Human task workflows** — model multi-step approval processes (e.g., expense approval chain) where each approver is an activity worker and timeouts escalate stalled tasks.
- **Long-running background jobs** — execute multi-stage data processing that can span hours or days, with SWF preserving state across worker restarts and outages.
- **Legacy workflow migration** — integrate existing worker code that cannot be refactored into Lambda functions; SWF's polling model lets any language or runtime participate as a worker.

## CLI Quick Reference (awslocal)

### Register a domain
```bash
awslocal swf register-domain \
  --name my-workflow-domain \
  --workflow-execution-retention-period-in-days 7 \
  --description "Order fulfillment domain"
```

### List domains
```bash
awslocal swf list-domains \
  --registration-status REGISTERED \
  --query 'domainInfos[].{Name:name,Status:status}' \
  --output table
```

### Register a workflow type
```bash
awslocal swf register-workflow-type \
  --domain my-workflow-domain \
  --name OrderFulfillment \
  --workflow-version "1.0" \
  --default-task-list "name=main-tasklist" \
  --default-execution-start-to-close-timeout 3600 \
  --default-task-start-to-close-timeout 300
```

### Register an activity type
```bash
awslocal swf register-activity-type \
  --domain my-workflow-domain \
  --name ProcessPayment \
  --activity-version "1.0" \
  --default-task-list "name=main-tasklist" \
  --default-task-schedule-to-close-timeout 600 \
  --default-task-start-to-close-timeout 300
```

### Start a workflow execution
```bash
awslocal swf start-workflow-execution \
  --domain my-workflow-domain \
  --workflow-id order-exec-001 \
  --workflow-type "name=OrderFulfillment,version=1.0" \
  --task-list "name=main-tasklist" \
  --input '{"orderId":"ORD-007"}' \
  --execution-start-to-close-timeout 3600
```

### List open executions
```bash
awslocal swf list-open-workflow-executions \
  --domain my-workflow-domain \
  --oldest-date 1 \
  --query 'executionInfos[].{WorkflowId:execution.workflowId,Status:executionStatus}' \
  --output table
```

### List registered workflow types
```bash
awslocal swf list-workflow-types \
  --domain my-workflow-domain \
  --registration-status REGISTERED \
  --query 'typeInfos[].{Name:workflowType.name,Version:workflowType.version}' \
  --output table
```

### Describe an execution
```bash
awslocal swf describe-workflow-execution \
  --domain my-workflow-domain \
  --execution "workflowId=order-exec-001,runId=<runId>"
```

### Deprecate a workflow type
```bash
awslocal swf deprecate-workflow-type \
  --domain my-workflow-domain \
  --workflow-type "name=OrderFulfillment,version=1.0"
```

## Example Walkthrough

1. **Register a domain** — the top-level namespace for all workflow resources in this project.
   ```bash
   awslocal swf register-domain \
     --name demo-workflow-domain \
     --workflow-execution-retention-period-in-days 7 \
     --description "Demo order fulfillment domain"
   echo "Domain registered"
   ```

2. **Register a workflow type** — define the OrderFulfillment blueprint with default timeouts.
   ```bash
   awslocal swf register-workflow-type \
     --domain demo-workflow-domain \
     --name OrderFulfillment \
     --workflow-version "1.0" \
     --default-task-list "name=demo-tasklist" \
     --default-execution-start-to-close-timeout 3600 \
     --default-task-start-to-close-timeout 300
   echo "Workflow type registered"
   ```

3. **Register an activity type** — define the ProcessOrder activity workers will pick up.
   ```bash
   awslocal swf register-activity-type \
     --domain demo-workflow-domain \
     --name ProcessOrder \
     --activity-version "1.0" \
     --default-task-list "name=demo-tasklist" \
     --default-task-schedule-to-close-timeout 600 \
     --default-task-start-to-close-timeout 300
   echo "Activity type registered"
   ```

4. **Start a workflow execution** — launch an instance with a sample order payload and capture the run ID.
   ```bash
   RUN_ID=$(awslocal swf start-workflow-execution \
     --domain demo-workflow-domain \
     --workflow-id "order-exec-$(date +%s)" \
     --workflow-type "name=OrderFulfillment,version=1.0" \
     --task-list "name=demo-tasklist" \
     --input '{"orderId":"ORD-007","items":[{"sku":"ITEM-1","qty":2}]}' \
     --execution-start-to-close-timeout 3600 \
     --output text --query 'runId')
   echo "Run ID: $RUN_ID"
   ```

5. **List open executions** — confirm the workflow is running in the domain.
   ```bash
   awslocal swf list-open-workflow-executions \
     --domain demo-workflow-domain \
     --oldest-date 1 \
     --query 'executionInfos[].{WorkflowId:execution.workflowId,Status:executionStatus}' \
     --output table
   ```

6. **List registered workflow types** — verify the type is available for future executions.
   ```bash
   awslocal swf list-workflow-types \
     --domain demo-workflow-domain \
     --registration-status REGISTERED \
     --query 'typeInfos[].{Name:workflowType.name,Version:workflowType.version}' \
     --output table
   ```

7. **List registered activity types** — confirm all activities are registered and ready.
   ```bash
   awslocal swf list-activity-types \
     --domain demo-workflow-domain \
     --registration-status REGISTERED \
     --query 'typeInfos[].{Name:activityType.name,Version:activityType.version}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--domain` | The SWF domain namespace | `my-workflow-domain` |
| `--name` | Name of the workflow type, activity type, or domain | `OrderFulfillment` |
| `--workflow-version` / `--activity-version` | Version string for a workflow or activity type | `"1.0"` |
| `--workflow-id` | User-supplied unique ID for a specific execution | `order-exec-001` |
| `--workflow-type` | `name=` and `version=` pair identifying the type to start | `name=OrderFulfillment,version=1.0` |
| `--default-task-list` | Task list workers poll to receive decision or activity tasks | `name=main-tasklist` |
| `--execution-start-to-close-timeout` | Maximum seconds a workflow execution may run end-to-end | `3600` |
| `--default-task-start-to-close-timeout` | Maximum seconds a single decision or activity task may run | `300` |
| `--input` | JSON string passed as input to the first decision task | `'{"orderId":"ORD-007"}'` |
| `--workflow-execution-retention-period-in-days` | How long completed execution history is stored | `7` |
| `--registration-status` | Filter for `list-*` commands | `REGISTERED` or `DEPRECATED` |
| `--oldest-date` | Unix timestamp (or relative days) lower bound for execution list queries | `1` |

## How to Run the Demo

```bash
cd services/11-integration/swf
bash demo.sh
```

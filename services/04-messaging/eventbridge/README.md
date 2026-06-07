# Amazon EventBridge

## What is it?
Amazon EventBridge is a serverless event bus that makes it easy to connect applications together using events from your own services, AWS services, and third-party SaaS applications. You define rules with event patterns or schedules, and EventBridge routes matching events to one or more targets — Lambda functions, SQS queues, Step Functions, API destinations, and more. It decouples event producers from consumers completely: publishers put events on a bus without knowing who is listening, and each consumer independently filters only the events it cares about. EventBridge is the modern, recommended replacement for CloudWatch Events.

## Key Concepts
- **Event Bus** — The channel through which events flow. AWS provides a default bus (`default`) for AWS service events; you create custom buses for your own applications.
- **Event** — A JSON object describing something that happened. It always contains `source`, `detail-type`, `detail`, `time`, and metadata fields.
- **Rule** — A configuration attached to an event bus that evaluates incoming events against an **event pattern** or a **schedule expression**, then routes matches to targets.
- **Event Pattern** — A JSON filter that specifies which event fields and values a rule should match (e.g., `{"source":["myapp.orders"],"detail-type":["OrderPlaced"]}`).
- **Target** — The downstream resource that receives a matched event. One rule can route to up to 5 targets simultaneously.
- **Schema Registry** — A catalog of event schemas; EventBridge can auto-discover and register schemas so you get type-safe code bindings.

## When to Use
- **Microservice choreography** — an order service publishes `OrderPlaced` events; inventory, billing, and notification services each subscribe independently without coupling.
- **Scheduled tasks** — replace cron jobs with EventBridge Scheduler rules that trigger Lambda functions on a fixed rate or cron expression.
- **SaaS integration** — ingest events from third-party partners (GitHub, Zendesk, Datadog) directly onto an event bus without writing ingestion code.
- **Cross-account event routing** — forward events from one AWS account's event bus to another for centralized event processing.

## CLI Quick Reference (awslocal)

### Event bus operations

| Action | Command |
|---|---|
| Create custom bus | `awslocal events create-event-bus --name my-app-events` |
| List event buses | `awslocal events list-event-buses` |
| Describe event bus | `awslocal events describe-event-bus --name my-app-events` |
| Delete event bus | `awslocal events delete-event-bus --name my-app-events` |

### Rule operations

| Action | Command |
|---|---|
| Create event-pattern rule | `awslocal events put-rule --name my-rule --event-bus-name my-app-events --event-pattern '{"source":["myapp.orders"],"detail-type":["OrderPlaced"]}' --state ENABLED` |
| Create scheduled rule | `awslocal events put-rule --name hourly-job --schedule-expression "rate(1 hour)" --state ENABLED` |
| List rules | `awslocal events list-rules --event-bus-name my-app-events` |
| Delete rule | `awslocal events delete-rule --name my-rule --event-bus-name my-app-events` |

### Target and event operations

| Action | Command |
|---|---|
| Add SQS target to rule | `awslocal events put-targets --rule my-rule --event-bus-name my-app-events --targets '[{"Id":"t1","Arn":"<QUEUE_ARN>"}]'` |
| Remove target | `awslocal events remove-targets --rule my-rule --event-bus-name my-app-events --ids t1` |
| Publish events | `awslocal events put-events --entries '[{"Source":"myapp.orders","DetailType":"OrderPlaced","Detail":"{\"orderId\":\"ORD-100\"}","EventBusName":"my-app-events"}]'` |

## Example Walkthrough

1. **Create a custom event bus** — a dedicated channel for your application events.
   ```bash
   awslocal events create-event-bus --name demo-app-events
   BUS_ARN=$(awslocal events describe-event-bus --name demo-app-events \
     --output text --query 'Arn')
   echo "Bus ARN: $BUS_ARN"
   ```

2. **Create an SQS queue as the event target** — matched events will be delivered here.
   ```bash
   awslocal sqs create-queue --queue-name eventbridge-target-queue
   QUEUE_URL=$(awslocal sqs get-queue-url --queue-name eventbridge-target-queue \
     --output text --query 'QueueUrl')
   QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" \
     --attribute-names QueueArn --output text --query 'Attributes.QueueArn')
   ```

3. **Create an event rule with a filter pattern** — only `OrderPlaced` events from `myapp.orders` will match.
   ```bash
   awslocal events put-rule \
     --name demo-order-rule \
     --event-bus-name demo-app-events \
     --event-pattern '{"source":["myapp.orders"],"detail-type":["OrderPlaced"]}' \
     --state ENABLED
   ```

4. **Attach the SQS queue as a target for the rule** — matched events are delivered to this queue.
   ```bash
   awslocal events put-targets \
     --rule demo-order-rule \
     --event-bus-name demo-app-events \
     --targets "[{\"Id\":\"sqs-target\",\"Arn\":\"$QUEUE_ARN\"}]"
   ```

5. **Publish two events — only one should match the rule** — `OrderPlaced` matches; `OrderShipped` does not.
   ```bash
   awslocal events put-events --entries \
     "[{\"Source\":\"myapp.orders\",\"DetailType\":\"OrderPlaced\",\"Detail\":\"{\\\"orderId\\\":\\\"ORD-100\\\",\\\"amount\\\":59.99}\",\"EventBusName\":\"demo-app-events\"},
       {\"Source\":\"myapp.orders\",\"DetailType\":\"OrderShipped\",\"Detail\":\"{\\\"orderId\\\":\\\"ORD-099\\\"}\",\"EventBusName\":\"demo-app-events\"}]"
   ```

6. **Read matched events from the SQS queue** — confirm only the `OrderPlaced` event arrived.
   ```bash
   awslocal sqs receive-message \
     --queue-url "$QUEUE_URL" \
     --max-number-of-messages 5 \
     --wait-time-seconds 2 | python3 -m json.tool
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--event-bus-name` | Name of the bus to attach a rule to. Omit to use the `default` bus. |
| `--event-pattern` | JSON filter object. Supports prefix, suffix, wildcard, exists, and numeric matchers. |
| `--schedule-expression` | Cron or rate expression for time-based rules: `rate(5 minutes)`, `cron(0 12 * * ? *)`. |
| `--state` | `ENABLED` or `DISABLED`. Disabled rules do not route events. |
| `--targets` | JSON array of target objects, each with `Id` (unique per rule) and `Arn`. |
| `--entries` | Array of event objects for `put-events`. Each entry must have `Source`, `DetailType`, and `Detail`. |
| `--detail` | Must be a valid JSON string (even if the content is minimal like `"{}"`). |
| `--input-transformer` | Reshape the event payload before delivering it to a target. |

## How to Run the Demo

```bash
cd services/04-messaging/eventbridge
bash demo.sh
```

# Amazon Simple Notification Service (SNS)

## What is it?
Amazon Simple Notification Service (SNS) is a fully managed pub/sub (publish-subscribe) messaging service that lets you fan out messages to a large number of subscribers simultaneously. Publishers send a single message to an SNS Topic, and SNS instantly delivers copies to every subscriber — which can be SQS queues, Lambda functions, HTTP endpoints, email addresses, or SMS. This decouples event producers from consumers so neither side needs to know about the other. SNS is ideal for broadcasting notifications, triggering multiple downstream systems from a single event, or alerting operators in real time.

## Key Concepts
- **Topic** — A named channel to which publishers send messages and subscribers listen. Identified by its ARN.
- **Publisher** — Any application or service that calls `sns publish` to send a message to a topic.
- **Subscriber** — An endpoint (SQS, Lambda, HTTP/S, email, SMS, mobile push) registered to receive copies of every message published to a topic.
- **Subscription** — The binding between a topic and a subscriber endpoint; confirmed before delivery begins.
- **Message Filtering** — A subscription filter policy (JSON) that limits which messages are delivered to that subscriber based on message attributes.
- **Message Attributes** — Key-value metadata attached to a published message; used for routing via filter policies.

## When to Use
- **Fan-out architecture** — publish one order-placed event and simultaneously trigger a fulfillment service, a notification email, and an analytics pipeline.
- **Operational alerting** — send CloudWatch alarms or custom alerts to an ops team via email, SMS, or a Slack webhook (HTTP endpoint).
- **Cross-service event broadcasting** — notify multiple microservices about a state change without coupling them to each other.
- **Mobile push notifications** — deliver targeted messages to iOS, Android, or web browser endpoints at scale.

## CLI Quick Reference (awslocal)

### Topic operations

| Action | Command |
|---|---|
| Create topic | `awslocal sns create-topic --name my-notifications` |
| List topics | `awslocal sns list-topics` |
| Describe topic | `awslocal sns get-topic-attributes --topic-arn <ARN>` |
| Delete topic | `awslocal sns delete-topic --topic-arn <ARN>` |

### Subscription operations

| Action | Command |
|---|---|
| Subscribe SQS queue | `awslocal sns subscribe --topic-arn <ARN> --protocol sqs --notification-endpoint <QUEUE_ARN>` |
| Subscribe HTTP endpoint | `awslocal sns subscribe --topic-arn <ARN> --protocol https --notification-endpoint https://example.com/hook` |
| Subscribe email | `awslocal sns subscribe --topic-arn <ARN> --protocol email --notification-endpoint user@example.com` |
| List subscriptions | `awslocal sns list-subscriptions-by-topic --topic-arn <ARN>` |
| Unsubscribe | `awslocal sns unsubscribe --subscription-arn <SUB_ARN>` |

### Publish

| Action | Command |
|---|---|
| Publish message | `awslocal sns publish --topic-arn <ARN> --message '{"type":"alert"}' --subject "Alert"` |
| Publish with attributes | `awslocal sns publish --topic-arn <ARN> --message "hello" --message-attributes '{"env":{"DataType":"String","StringValue":"prod"}}'` |

## Example Walkthrough

1. **Create an SNS topic** — the central broadcast channel for your notifications.
   ```bash
   TOPIC_ARN=$(awslocal sns create-topic --name demo-notifications \
     --output text --query 'TopicArn')
   echo "Topic ARN: $TOPIC_ARN"
   ```

2. **Create an SQS queue to act as a subscriber** — messages published to the topic will land here.
   ```bash
   awslocal sqs create-queue --queue-name sns-subscriber-queue
   QUEUE_URL=$(awslocal sqs get-queue-url --queue-name sns-subscriber-queue \
     --output text --query 'QueueUrl')
   QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" \
     --attribute-names QueueArn --output text --query 'Attributes.QueueArn')
   ```

3. **Subscribe the SQS queue to the topic** — every published message will be delivered to the queue.
   ```bash
   awslocal sns subscribe \
     --topic-arn "$TOPIC_ARN" \
     --protocol sqs \
     --notification-endpoint "$QUEUE_ARN"
   ```

4. **Publish a message to the topic** — SNS fans this out to all subscribers immediately.
   ```bash
   awslocal sns publish \
     --topic-arn "$TOPIC_ARN" \
     --message '{"type":"alert","severity":"high","message":"CPU usage above 90%"}' \
     --subject "System Alert" \
     --message-attributes '{"category":{"DataType":"String","StringValue":"infrastructure"}}'
   ```

5. **Confirm delivery — read messages from the SQS subscriber**.
   ```bash
   awslocal sqs receive-message \
     --queue-url "$QUEUE_URL" \
     --max-number-of-messages 5 \
     --wait-time-seconds 2 | python3 -m json.tool
   ```

6. **List all subscriptions on the topic** — see what endpoints are registered.
   ```bash
   awslocal sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN"
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--topic-arn` | The ARN of the target SNS topic. |
| `--protocol` | Delivery protocol: `sqs`, `lambda`, `http`, `https`, `email`, `sms`, `application`. |
| `--notification-endpoint` | The subscriber endpoint URI or ARN. |
| `--message` | The message body string (up to 256 KB). |
| `--subject` | Optional subject line (used for email and stored in the SNS envelope). |
| `--message-attributes` | JSON object of key-value attributes for filtering. |
| `--message-structure json` | Send different payloads to different protocols in one publish call. |
| `--subscription-arn` | ARN of a specific subscription; used with `unsubscribe` and `get-subscription-attributes`. |

## How to Run the Demo

```bash
cd services/04-messaging/sns
bash demo.sh
```

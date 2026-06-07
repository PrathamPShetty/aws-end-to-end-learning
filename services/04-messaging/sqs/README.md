# Amazon Simple Queue Service (SQS)

## What is it?
Amazon Simple Queue Service (SQS) is a fully managed message queuing service that enables you to decouple and scale microservices, distributed systems, and serverless applications. It acts as a buffer between producers and consumers — producers send messages to a queue, and consumers poll the queue to receive and process them independently. SQS guarantees at-least-once delivery and supports both standard queues (high throughput, best-effort ordering) and FIFO queues (exactly-once processing, strict ordering). It eliminates the complexity of managing and operating message-oriented middleware.

## Key Concepts
- **Queue** — A named buffer that holds messages until a consumer retrieves and deletes them.
- **Message** — The unit of data sent to a queue (up to 256 KB); can be plain text or JSON.
- **Visibility Timeout** — After a consumer receives a message, it is hidden from other consumers for this duration (default 30 s). The consumer must delete it before the timeout expires, otherwise it reappears.
- **Dead Letter Queue (DLQ)** — A separate queue that receives messages which have been received and failed processing more than `maxReceiveCount` times.
- **Redrive Policy** — The configuration that links a source queue to a DLQ and sets `maxReceiveCount`.
- **Long Polling** — Setting `WaitTimeSeconds` (up to 20 s) so a receive call waits for a message to arrive, reducing empty responses and cost.

## When to Use
- **Order processing pipelines** — an e-commerce backend places orders on a queue; a separate fulfillment service processes them at its own pace.
- **Task offloading** — a web server queues image-resize jobs so the API responds immediately while workers handle heavy lifting asynchronously.
- **Fault-tolerant workflows** — use a DLQ to catch and inspect messages that fail repeatedly without losing them.
- **Rate limiting between services** — smooth out traffic spikes so a downstream service is never overwhelmed by a sudden burst of events.

## CLI Quick Reference (awslocal)

### Queue operations

| Action | Command |
|---|---|
| Create standard queue | `awslocal sqs create-queue --queue-name my-queue` |
| Create FIFO queue | `awslocal sqs create-queue --queue-name my-queue.fifo --attributes FifoQueue=true,ContentBasedDeduplication=true` |
| List queues | `awslocal sqs list-queues` |
| Get queue URL | `awslocal sqs get-queue-url --queue-name my-queue` |
| Get queue attributes | `awslocal sqs get-queue-attributes --queue-url <URL> --attribute-names All` |
| Delete queue | `awslocal sqs delete-queue --queue-url <URL>` |

### Message operations

| Action | Command |
|---|---|
| Send message | `awslocal sqs send-message --queue-url <URL> --message-body '{"orderId":"ORD-001"}'` |
| Receive messages | `awslocal sqs receive-message --queue-url <URL> --max-number-of-messages 5 --wait-time-seconds 5` |
| Delete message | `awslocal sqs delete-message --queue-url <URL> --receipt-handle <HANDLE>` |
| Purge queue | `awslocal sqs purge-queue --queue-url <URL>` |

## Example Walkthrough

1. **Create a Dead Letter Queue** — holds messages that fail too many times.
   ```bash
   DLQ_URL=$(awslocal sqs create-queue --queue-name orders-dlq \
     --output text --query 'QueueUrl')
   DLQ_ARN=$(awslocal sqs get-queue-attributes \
     --queue-url "$DLQ_URL" \
     --attribute-names QueueArn \
     --output text --query 'Attributes.QueueArn')
   ```

2. **Create the main queue with a redrive policy** — messages that fail 3 times are sent to the DLQ.
   ```bash
   awslocal sqs create-queue \
     --queue-name orders-queue \
     --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
   QUEUE_URL=$(awslocal sqs get-queue-url --queue-name orders-queue \
     --output text --query 'QueueUrl')
   ```

3. **Send a message** — a producer places an order event onto the queue.
   ```bash
   awslocal sqs send-message \
     --queue-url "$QUEUE_URL" \
     --message-body '{"event":"order_placed","orderId":"ORD-001","amount":99.99}'
   ```

4. **Receive messages** — a consumer polls the queue to fetch up to 5 messages.
   ```bash
   MESSAGES=$(awslocal sqs receive-message \
     --queue-url "$QUEUE_URL" \
     --max-number-of-messages 5 \
     --wait-time-seconds 5)
   echo "$MESSAGES" | python3 -m json.tool
   ```

5. **Delete the processed message** — remove it from the queue after successful processing.
   ```bash
   RECEIPT=$(echo "$MESSAGES" | python3 -c \
     "import sys,json; msgs=json.load(sys.stdin).get('Messages',[]); print(msgs[0]['ReceiptHandle']) if msgs else print('')")
   awslocal sqs delete-message \
     --queue-url "$QUEUE_URL" \
     --receipt-handle "$RECEIPT"
   ```

6. **Check queue depth** — verify how many messages remain visible or in-flight.
   ```bash
   awslocal sqs get-queue-attributes \
     --queue-url "$QUEUE_URL" \
     --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--queue-name` | Name of the queue. FIFO queues must end in `.fifo`. |
| `--max-number-of-messages` | Number of messages to retrieve per call (1–10). |
| `--wait-time-seconds` | Enables long polling (0–20 s). Use `> 0` to reduce empty responses. |
| `--visibility-timeout` | Seconds a received message stays hidden (default 30, max 43200). |
| `--message-retention-period` | How long messages are kept if not deleted (60–1209600 s). |
| `--receipt-handle` | Token returned with a received message; required to delete or change visibility. |
| `--delay-seconds` | Delay before a message becomes visible after being sent (0–900 s). |
| `--attribute-names All` | Returns all queue attributes in `get-queue-attributes`. |

## How to Run the Demo

```bash
cd services/04-messaging/sqs
bash demo.sh
```

# Amazon MQ

## What is it?
Amazon MQ is a managed message broker service for Apache ActiveMQ and RabbitMQ that lets you migrate existing applications using standard messaging protocols without rewriting them. Unlike SQS and SNS which are AWS-native APIs, Amazon MQ speaks industry-standard protocols: AMQP, MQTT, OpenWire, STOMP, and WebSocket. This means applications already using these protocols can connect with minimal or no code changes. Amazon MQ handles broker provisioning, patching, high availability, and storage so you focus on your messaging logic rather than broker operations.

## Key Concepts
- **Broker** — The managed message server instance. You choose the engine type (ActiveMQ or RabbitMQ), instance size, and deployment mode.
- **Engine Type** — Either `ACTIVEMQ` or `RABBITMQ`. ActiveMQ supports JMS and multiple protocols; RabbitMQ uses AMQP 0-9-1.
- **Deployment Mode** — `SINGLE_INSTANCE` (dev/test) or `ACTIVE_STANDBY_MULTI_AZ` (production high availability).
- **Endpoint** — The connection URL(s) your application uses to connect to the broker (e.g., `stomp+ssl://broker.mq.us-east-1.amazonaws.com:61614`).
- **User** — A broker-level credential (username + password) with optional group membership (`admin`). Required to authenticate connecting clients.
- **Configuration** — An XML document (for ActiveMQ) or definition file (for RabbitMQ) that customizes broker settings. Can be applied at creation or updated later.

## When to Use
- **Lift-and-shift migrations** — move an on-premises ActiveMQ or RabbitMQ deployment to AWS without changing the application protocol or client library.
- **Enterprise JMS applications** — Java EE applications that use JMS (Java Message Service) and require ActiveMQ's full feature set including transactions, persistent subscriptions, and virtual destinations.
- **Protocol diversity** — when multiple services use different messaging protocols (MQTT for IoT devices, STOMP for web clients, OpenWire for Java apps) and need to communicate through a single broker.
- **Guaranteed message ordering and transactions** — use cases requiring strict delivery guarantees, message grouping, or XA transactions that simpler services like SQS do not provide.

## CLI Quick Reference (awslocal)

### Broker operations

| Action | Command |
|---|---|
| Create ActiveMQ broker | `awslocal mq create-broker --broker-name my-broker --engine-type ACTIVEMQ --engine-version 5.15.14 --host-instance-type mq.m5.large --deployment-mode SINGLE_INSTANCE --publicly-accessible --users '[{"Username":"admin","Password":"Admin123!","Groups":["admin"]}]'` |
| List brokers | `awslocal mq list-brokers` |
| Describe broker | `awslocal mq describe-broker --broker-id <BROKER_ID>` |
| Reboot broker | `awslocal mq reboot-broker --broker-id <BROKER_ID>` |
| Delete broker | `awslocal mq delete-broker --broker-id <BROKER_ID>` |
| Update broker | `awslocal mq update-broker --broker-id <BROKER_ID> --auto-minor-version-upgrade` |

### Configuration operations

| Action | Command |
|---|---|
| Create configuration | `awslocal mq create-configuration --name my-config --engine-type ACTIVEMQ --engine-version 5.15.14` |
| List configurations | `awslocal mq list-configurations` |
| Describe configuration | `awslocal mq describe-configuration --configuration-id <CONFIG_ID>` |

### User operations

| Action | Command |
|---|---|
| Create user | `awslocal mq create-user --broker-id <BROKER_ID> --username newuser --password NewPass123!` |
| List users | `awslocal mq list-users --broker-id <BROKER_ID>` |
| Delete user | `awslocal mq delete-user --broker-id <BROKER_ID> --username newuser` |

## Example Walkthrough

1. **Create an ActiveMQ broker** — a single-instance broker for development and testing.
   ```bash
   BROKER_ID=$(awslocal mq create-broker \
     --broker-name demo-activemq-broker \
     --engine-type ACTIVEMQ \
     --engine-version "5.15.14" \
     --host-instance-type "mq.m5.large" \
     --deployment-mode SINGLE_INSTANCE \
     --publicly-accessible \
     --users '[{"Username":"demouser","Password":"DemoPass123!","Groups":["admin"]}]' \
     --output text --query 'BrokerId')
   echo "Broker ID: $BROKER_ID"
   ```

2. **Wait for the broker to reach RUNNING state** — provisioning takes a few minutes in real AWS.
   ```bash
   until [ "$(awslocal mq describe-broker --broker-id "$BROKER_ID" \
     --output text --query 'BrokerState')" = "RUNNING" ]; do
     echo "Waiting..."; sleep 2
   done
   echo "Broker is RUNNING."
   ```

3. **Describe the broker and view its details** — check engine version, state, and instance type.
   ```bash
   awslocal mq describe-broker --broker-id "$BROKER_ID" \
     --output table \
     --query '{Name:BrokerName,State:BrokerState,Engine:EngineType,Version:EngineVersion}'
   ```

4. **Get the broker endpoints** — the connection URLs your application will use.
   ```bash
   awslocal mq describe-broker --broker-id "$BROKER_ID" \
     --output text \
     --query 'BrokerInstances[*].Endpoints[]'
   ```

5. **Create a broker configuration** — an XML-based settings document for ActiveMQ.
   ```bash
   awslocal mq create-configuration \
     --name demo-activemq-config \
     --engine-type ACTIVEMQ \
     --engine-version "5.15.14"
   ```

6. **List all MQ brokers** — see every broker and its current state.
   ```bash
   awslocal mq list-brokers --output table \
     --query 'BrokerSummaries[*].{Name:BrokerName,ID:BrokerId,State:BrokerState}'
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--engine-type` | `ACTIVEMQ` or `RABBITMQ`. Determines protocols and features available. |
| `--engine-version` | ActiveMQ version (e.g., `5.15.14`, `5.17.6`) or RabbitMQ version (e.g., `3.11.20`). |
| `--host-instance-type` | EC2-like instance size: `mq.t3.micro`, `mq.m5.large`, etc. Affects throughput and memory. |
| `--deployment-mode` | `SINGLE_INSTANCE` (one broker) or `ACTIVE_STANDBY_MULTI_AZ` (two brokers across AZs for HA). |
| `--publicly-accessible` | If set, the broker endpoint is reachable from outside the VPC. |
| `--users` | JSON array of initial broker users with `Username`, `Password`, and optional `Groups`. |
| `--auto-minor-version-upgrade` | Enables automatic minor version upgrades during the maintenance window. |
| `--broker-id` | The ID returned at creation time; required for all subsequent operations on the broker. |

## How to Run the Demo

```bash
cd services/04-messaging/mq
bash demo.sh
```

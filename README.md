# AWS Zero to Prod — Local AWS Learning Environment

A local AWS learning environment using **LocalStack** (current) with **Floci** as an alternative emulator.
All AWS services run on `localhost:4566` — no real AWS account needed.

---

## Emulators: LocalStack vs Floci

| Feature | LocalStack | Floci |
|---|---|---|
| **Image** | `localstack/localstack` | `floci/floci` |
| **Free tier** | Yes (needs free auth token) | Yes (no token needed) |
| **Web UI** | Yes — `app.localstack.cloud` | No |
| **Services** | 70+ AWS services | S3, SQS, SNS, DynamoDB, Lambda, IAM, EC2, STS |
| **Persistence** | Yes | Yes |
| **Best for** | Full AWS learning + web dashboard | Lightweight / offline use |

---

## Current Setup — LocalStack (Recommended)

The `docker-compose.yml` is configured to run LocalStack with a free auth token.

### Prerequisites

- Docker
- Python 3.x
- Free LocalStack account at `https://app.localstack.cloud`

### Start

```bash
docker-compose up -d
```

### Verify it's running

```bash
curl http://localhost:4566/_localstack/health
```

### Web UI

1. Go to `https://app.localstack.cloud`
2. Sign in → **Instances** in the sidebar
3. Your local instance auto-connects at `http://localhost:4566`

### Auth Token

The `LOCALSTACK_AUTH_TOKEN` is set in `docker-compose.yml`.
Get your token from `https://app.localstack.cloud` → **Auth Token**.

---

## Alternative Setup — Floci (Lightweight)

Floci requires no account or token. Swap it in by editing `docker-compose.yml`:

```yaml
services:
  floci:
    image: floci/floci:latest
    ports:
      - "4566:4566"
    volumes:
      - ./data:/app/data
```

Then restart:

```bash
docker-compose down
docker-compose up -d
```

> Floci has no web UI. Use `awslocal` CLI or a tool like Cyberduck (S3 only).

---

## Using the AWS CLI

**1. Activate the virtual environment**

```bash
source .venv/bin/activate
```

**2. Set credentials (both emulators accept dummy values)**

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

**3. Run commands**

```bash
# awslocal (recommended — no endpoint flag needed)
awslocal s3 mb s3://my-bucket
awslocal s3 ls

# Standard aws CLI
aws --endpoint-url http://localhost:4566 s3 ls
```

---

## Supported Services

| Service | LocalStack | Floci | Example Command |
|---------|:----------:|:-----:|-----------------|
| S3 | ✅ | ✅ | `awslocal s3 ls` |
| SQS | ✅ | ✅ | `awslocal sqs list-queues` |
| SNS | ✅ | ✅ | `awslocal sns list-topics` |
| DynamoDB | ✅ | ✅ | `awslocal dynamodb list-tables` |
| Lambda | ✅ | ✅ | `awslocal lambda list-functions` |
| IAM | ✅ | ✅ | `awslocal iam list-users` |
| EC2 | ✅ | ✅ | `awslocal ec2 describe-instances` |
| STS | ✅ | ✅ | `awslocal sts get-caller-identity` |
| Kinesis | ✅ | ❌ | `awslocal kinesis list-streams` |
| RDS | ✅ | ❌ | `awslocal rds describe-db-instances` |
| CloudFormation | ✅ | ❌ | `awslocal cloudformation list-stacks` |
| Secrets Manager | ✅ | ❌ | `awslocal secretsmanager list-secrets` |
| SSM | ✅ | ❌ | `awslocal ssm describe-parameters` |
| CloudWatch | ✅ | ❌ | `awslocal logs describe-log-groups` |

---

## Project Structure

```
aws/
├── docker-compose.yml          # LocalStack container config
├── .gitignore
├── README.md                   # This file
├── AWS_SERVICES_REFERENCE.md   # Full CLI reference for all services
├── LEARNING_PLAN.md            # Step-by-step learning plan
├── ecommerce/                  # Sample project using all services
│   ├── setup.sh                # Create all AWS resources
│   ├── teardown.sh             # Remove all AWS resources
│   ├── lambdas/
│   │   ├── place_order/        # Lambda: save order, publish to SNS, stream to Kinesis
│   │   ├── notification_processor/ # Lambda: create S3 invoice from SQS
│   │   └── inventory_processor/    # Lambda: update DynamoDB stock from SQS
│   └── scripts/
│       ├── place_order.sh      # Place a test order
│       └── check_status.sh     # View all resource state
└── .venv/                      # Python virtualenv (awslocal, awscli)
```

---

## Sample Project — E-Commerce Order System

A full working project that uses all AWS services together.

```
place_order.sh
      │
      ▼
Lambda (place-order)
      ├──► DynamoDB  — saves order
      ├──► SNS       — publishes order_placed event
      │       ├──► SQS → Lambda → S3  (creates invoice)
      │       └──► SQS → Lambda → DynamoDB  (updates stock)
      └──► Kinesis   — streams analytics event
```

```bash
cd ecommerce

# Setup all resources
./setup.sh

# Place orders
./scripts/place_order.sh laptop 2 999.99
./scripts/place_order.sh phone 1 499.99

# Check everything
./scripts/check_status.sh

# Tear down
./teardown.sh
```

---

## Stop / Restart

```bash
# Stop
docker-compose down

# Restart
docker-compose up -d

# View logs
docker-compose logs -f
```

## Data Persistence

Data is saved in `./data/` (mounted into the container) and survives restarts.
To reset all data: `docker-compose down && rm -rf ./data/* && docker-compose up -d`

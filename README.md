# Local AWS Emulator (Floci)

A local AWS emulator using [Floci](https://floci.io) running on port `4566`, compatible with the AWS CLI.

## Prerequisites

- Docker
- Python 3.x

## Setup

**1. Start the container**

```bash
docker-compose up -d
```

**2. Activate the virtual environment**

```bash
source .venv/bin/activate
```

**3. Set dummy AWS credentials**

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

## Usage

Use either `awslocal` (shorthand, no endpoint flag needed) or standard `aws` with `--endpoint-url`:

```bash
# Using awslocal (recommended)
awslocal s3 mb s3://my-bucket
awslocal s3 ls

# Using aws CLI directly
aws --endpoint-url http://localhost:4566 s3 mb s3://my-bucket
aws --endpoint-url http://localhost:4566 s3 ls
```

## Supported Services

| Service    | Example Command                              |
|------------|----------------------------------------------|
| S3         | `awslocal s3 ls`                             |
| SQS        | `awslocal sqs list-queues`                   |
| SNS        | `awslocal sns list-topics`                   |
| DynamoDB   | `awslocal dynamodb list-tables`              |
| Lambda     | `awslocal lambda list-functions`             |
| IAM        | `awslocal iam list-users`                    |
| STS        | `awslocal sts get-caller-identity`           |
| EC2        | `awslocal ec2 describe-instances`            |

## Data Persistence

Data is persisted in the `./data` directory (mounted into the container).

## Stop the Container

```bash
docker-compose down
```

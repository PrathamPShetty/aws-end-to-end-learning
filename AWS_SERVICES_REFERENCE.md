# AWS Services Reference Guide

All commands use `awslocal` (auto-targets `localhost:4566`).
Replace with `aws --endpoint-url http://localhost:4566` if needed.

---

## Table of Contents

1. [IAM](#1-iam--identity--access-management)
2. [S3](#2-s3--simple-storage-service)
3. [DynamoDB](#3-dynamodb)
4. [RDS](#4-rds--relational-database-service)
5. [Lambda](#5-lambda)
6. [EC2](#6-ec2--elastic-compute-cloud)
7. [SQS](#7-sqs--simple-queue-service)
8. [SNS](#8-sns--simple-notification-service)
9. [Kinesis](#9-kinesis)
10. [CloudFormation](#10-cloudformation)
11. [STS](#11-sts--security-token-service)
12. [SSM Parameter Store](#12-ssm--parameter-store)
13. [Secrets Manager](#13-secrets-manager)
14. [CloudWatch](#14-cloudwatch)

---

## 1. IAM — Identity & Access Management

> Controls WHO can do WHAT on which AWS resources.
> Key concepts: Users, Groups, Roles, Policies, Permissions.

### Users

```bash
# Create a user
awslocal iam create-user --user-name alice

# List all users
awslocal iam list-users

# Get a specific user
awslocal iam get-user --user-name alice

# Delete a user
awslocal iam delete-user --user-name alice

# Create access keys for a user (programmatic access)
awslocal iam create-access-key --user-name alice

# List access keys
awslocal iam list-access-keys --user-name alice

# Delete access key
awslocal iam delete-access-key --user-name alice --access-key-id AKIAIOSFODNN7EXAMPLE
```

### Groups

```bash
# Create a group
awslocal iam create-group --group-name developers

# Add user to group
awslocal iam add-user-to-group --user-name alice --group-name developers

# List groups
awslocal iam list-groups

# List users in a group
awslocal iam get-group --group-name developers

# Remove user from group
awslocal iam remove-user-from-group --user-name alice --group-name developers

# Delete group
awslocal iam delete-group --group-name developers
```

### Policies

```bash
# Attach AWS managed policy to user
awslocal iam attach-user-policy \
  --user-name alice \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Attach AWS managed policy to group
awslocal iam attach-group-policy \
  --group-name developers \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Create a custom policy
awslocal iam create-policy \
  --policy-name MyS3Policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }]
  }'

# List policies attached to a user
awslocal iam list-attached-user-policies --user-name alice

# Detach policy from user
awslocal iam detach-user-policy \
  --user-name alice \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# List all managed policies
awslocal iam list-policies --scope AWS
```

### Roles (used by Lambda, EC2, etc.)

```bash
# Create a role (Lambda can assume it)
awslocal iam create-role \
  --role-name lambda-exec-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policy to role
awslocal iam attach-role-policy \
  --role-name lambda-exec-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# List roles
awslocal iam list-roles

# Get role details
awslocal iam get-role --role-name lambda-exec-role

# Delete role
awslocal iam delete-role --role-name lambda-exec-role
```

---

## 2. S3 — Simple Storage Service

> Object storage. Store any file (image, video, JSON, zip) in buckets.
> Key concepts: Buckets, Objects, Keys, Versioning, Lifecycle, Presigned URLs.

### Buckets

```bash
# Create bucket
awslocal s3 mb s3://my-bucket

# List all buckets
awslocal s3 ls

# Delete empty bucket
awslocal s3 rb s3://my-bucket

# Delete bucket with all contents
awslocal s3 rb s3://my-bucket --force

# Get bucket location
awslocal s3api get-bucket-location --bucket my-bucket
```

### Objects (files)

```bash
# Upload a file
awslocal s3 cp file.txt s3://my-bucket/

# Upload to a folder path
awslocal s3 cp file.txt s3://my-bucket/uploads/2024/file.txt

# Upload entire directory
awslocal s3 cp ./local-folder s3://my-bucket/folder/ --recursive

# Download a file
awslocal s3 cp s3://my-bucket/file.txt ./downloaded.txt

# Download entire folder
awslocal s3 cp s3://my-bucket/folder/ ./local-folder --recursive

# List objects in bucket
awslocal s3 ls s3://my-bucket

# List objects with prefix (folder)
awslocal s3 ls s3://my-bucket/uploads/

# Delete a file
awslocal s3 rm s3://my-bucket/file.txt

# Delete all files in a folder
awslocal s3 rm s3://my-bucket/uploads/ --recursive

# Move/rename a file
awslocal s3 mv s3://my-bucket/old.txt s3://my-bucket/new.txt

# Sync local folder to S3
awslocal s3 sync ./local-folder s3://my-bucket/folder/

# Sync S3 to local
awslocal s3 sync s3://my-bucket/folder/ ./local-folder
```

### Object metadata and content

```bash
# Get object metadata
awslocal s3api head-object --bucket my-bucket --key file.txt

# Put object with metadata
awslocal s3api put-object \
  --bucket my-bucket \
  --key file.txt \
  --body file.txt \
  --content-type "text/plain" \
  --metadata '{"author":"alice","version":"1.0"}'

# Get object (download via API)
awslocal s3api get-object \
  --bucket my-bucket \
  --key file.txt \
  output.txt

# Copy object between buckets
awslocal s3api copy-object \
  --copy-source my-bucket/file.txt \
  --bucket other-bucket \
  --key file.txt
```

### Versioning

```bash
# Enable versioning
awslocal s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled

# Get versioning status
awslocal s3api get-bucket-versioning --bucket my-bucket

# List all versions of all objects
awslocal s3api list-object-versions --bucket my-bucket

# Get specific version
awslocal s3api get-object \
  --bucket my-bucket \
  --key file.txt \
  --version-id VERSION_ID \
  output.txt

# Delete specific version
awslocal s3api delete-object \
  --bucket my-bucket \
  --key file.txt \
  --version-id VERSION_ID
```

### Lifecycle Rules

```bash
# Set lifecycle rule (delete objects after 30 days)
awslocal s3api put-bucket-lifecycle-configuration \
  --bucket my-bucket \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "expire-old-files",
      "Status": "Enabled",
      "Filter": {"Prefix": "logs/"},
      "Expiration": {"Days": 30}
    }]
  }'

# Get lifecycle rules
awslocal s3api get-bucket-lifecycle-configuration --bucket my-bucket
```

### Static Website Hosting

```bash
# Enable website hosting
awslocal s3 website s3://my-bucket/ \
  --index-document index.html \
  --error-document error.html

# Get website config
awslocal s3api get-bucket-website --bucket my-bucket
```

### Presigned URLs

```bash
# Generate presigned URL (expires in 1 hour)
awslocal s3 presign s3://my-bucket/file.txt --expires-in 3600
```

---

## 3. DynamoDB

> Serverless NoSQL database. No schema, scales automatically.
> Key concepts: Tables, Items, Partition Key, Sort Key, GSI, LSI, Streams.

### Tables

```bash
# Create table (partition key only)
awslocal dynamodb create-table \
  --table-name Users \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Create table (partition key + sort key)
awslocal dynamodb create-table \
  --table-name Orders \
  --attribute-definitions \
    AttributeName=customerId,AttributeType=S \
    AttributeName=orderId,AttributeType=S \
  --key-schema \
    AttributeName=customerId,KeyType=HASH \
    AttributeName=orderId,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

# Create table with Global Secondary Index (GSI)
awslocal dynamodb create-table \
  --table-name Products \
  --attribute-definitions \
    AttributeName=productId,AttributeType=S \
    AttributeName=category,AttributeType=S \
  --key-schema AttributeName=productId,KeyType=HASH \
  --global-secondary-indexes '[{
    "IndexName": "CategoryIndex",
    "KeySchema": [{"AttributeName":"category","KeyType":"HASH"}],
    "Projection": {"ProjectionType":"ALL"},
    "ProvisionedThroughput": {"ReadCapacityUnits":5,"WriteCapacityUnits":5}
  }]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# List all tables
awslocal dynamodb list-tables

# Describe table (schema, indexes, status)
awslocal dynamodb describe-table --table-name Users

# Delete table
awslocal dynamodb delete-table --table-name Users
```

### Items (CRUD)

```bash
# Put item (create/replace)
awslocal dynamodb put-item \
  --table-name Users \
  --item '{
    "userId":  {"S": "u-001"},
    "name":    {"S": "Alice"},
    "age":     {"N": "30"},
    "active":  {"BOOL": true},
    "tags":    {"L": [{"S":"admin"},{"S":"user"}]},
    "address": {"M": {"city":{"S":"NYC"},"zip":{"S":"10001"}}}
  }'

# Get item by key
awslocal dynamodb get-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}'

# Get item (specific attributes only)
awslocal dynamodb get-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}' \
  --projection-expression "name, age"

# Update item
awslocal dynamodb update-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}' \
  --update-expression "SET age = :a, #n = :n" \
  --expression-attribute-values '{":a":{"N":"31"},":n":{"S":"Alice Smith"}}' \
  --expression-attribute-names '{"#n":"name"}'

# Update item — increment a counter
awslocal dynamodb update-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}' \
  --update-expression "ADD loginCount :inc" \
  --expression-attribute-values '{":inc":{"N":"1"}}'

# Conditional update (only if condition is true)
awslocal dynamodb update-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}' \
  --update-expression "SET active = :val" \
  --condition-expression "age >= :min" \
  --expression-attribute-values '{":val":{"BOOL":false},":min":{"N":"18"}}'

# Delete item
awslocal dynamodb delete-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}'

# Delete item conditionally
awslocal dynamodb delete-item \
  --table-name Users \
  --key '{"userId":{"S":"u-001"}}' \
  --condition-expression "active = :f" \
  --expression-attribute-values '{":f":{"BOOL":false}}'
```

### Query & Scan

```bash
# Scan — reads every item (expensive on large tables)
awslocal dynamodb scan --table-name Users

# Scan with filter
awslocal dynamodb scan \
  --table-name Users \
  --filter-expression "age > :min" \
  --expression-attribute-values '{":min":{"N":"25"}}'

# Scan — specific columns only
awslocal dynamodb scan \
  --table-name Users \
  --projection-expression "userId, name"

# Query by partition key (fast)
awslocal dynamodb query \
  --table-name Orders \
  --key-condition-expression "customerId = :cid" \
  --expression-attribute-values '{":cid":{"S":"CUST-001"}}'

# Query with sort key range
awslocal dynamodb query \
  --table-name Orders \
  --key-condition-expression "customerId = :cid AND orderId BETWEEN :a AND :b" \
  --expression-attribute-values '{
    ":cid":{"S":"CUST-001"},
    ":a":{"S":"ORD-100"},
    ":b":{"S":"ORD-200"}
  }'

# Query on GSI
awslocal dynamodb query \
  --table-name Products \
  --index-name CategoryIndex \
  --key-condition-expression "category = :cat" \
  --expression-attribute-values '{":cat":{"S":"electronics"}}'

# Batch write (up to 25 items at once)
awslocal dynamodb batch-write-item \
  --request-items '{
    "Users": [
      {"PutRequest": {"Item": {"userId":{"S":"u-002"},"name":{"S":"Bob"},"age":{"N":"25"}}}},
      {"PutRequest": {"Item": {"userId":{"S":"u-003"},"name":{"S":"Carol"},"age":{"N":"28"}}}}
    ]
  }'

# Batch get (up to 100 items at once)
awslocal dynamodb batch-get-item \
  --request-items '{
    "Users": {
      "Keys": [
        {"userId":{"S":"u-001"}},
        {"userId":{"S":"u-002"}}
      ]
    }
  }'
```

### TTL (Auto-delete items)

```bash
# Enable TTL on a field
awslocal dynamodb update-time-to-live \
  --table-name Sessions \
  --time-to-live-specification "Enabled=true,AttributeName=expiresAt"

# Put item with TTL (Unix timestamp — 1 hour from now)
awslocal dynamodb put-item \
  --table-name Sessions \
  --item '{"sessionId":{"S":"s-001"},"expiresAt":{"N":"1735689600"}}'
```

---

## 4. RDS — Relational Database Service

> Managed SQL databases: PostgreSQL, MySQL, MariaDB, SQL Server, Oracle.
> Key concepts: DB Instances, Snapshots, Parameter Groups, Subnet Groups.

```bash
# Create PostgreSQL instance
awslocal rds create-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 14.0 \
  --master-username admin \
  --master-user-password Password123! \
  --allocated-storage 20 \
  --no-multi-az \
  --publicly-accessible

# Create MySQL instance
awslocal rds create-db-instance \
  --db-instance-identifier mysqldb \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username root \
  --master-user-password Password123! \
  --allocated-storage 20

# List all DB instances
awslocal rds describe-db-instances

# Describe specific instance
awslocal rds describe-db-instances \
  --db-instance-identifier mydb

# Create snapshot (backup)
awslocal rds create-db-snapshot \
  --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-snapshot-2024

# List snapshots
awslocal rds describe-db-snapshots

# Restore from snapshot
awslocal rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier mydb-restored \
  --db-snapshot-identifier mydb-snapshot-2024

# Modify instance (e.g. change class)
awslocal rds modify-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.small \
  --apply-immediately

# Reboot instance
awslocal rds reboot-db-instance \
  --db-instance-identifier mydb

# Delete instance
awslocal rds delete-db-instance \
  --db-instance-identifier mydb \
  --skip-final-snapshot
```

---

## 5. Lambda

> Run code without servers. Pay per invocation, scales automatically.
> Key concepts: Functions, Runtimes, Triggers, Layers, Concurrency, Event Source Mappings.

### Functions

```bash
# Package your code
zip function.zip handler.py

# Create function
awslocal lambda create-function \
  --function-name my-function \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/lambda-exec-role \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 256 \
  --environment Variables="{DB_TABLE=Users,BUCKET=my-bucket}"

# List functions
awslocal lambda list-functions

# Get function details
awslocal lambda get-function --function-name my-function

# Update function code
zip function.zip handler.py
awslocal lambda update-function-code \
  --function-name my-function \
  --zip-file fileb://function.zip

# Update function config (env vars, timeout, memory)
awslocal lambda update-function-configuration \
  --function-name my-function \
  --timeout 60 \
  --memory-size 512 \
  --environment Variables="{DB_TABLE=Orders}"

# Delete function
awslocal lambda delete-function --function-name my-function
```

### Invocation

```bash
# Invoke synchronously (wait for result)
echo '{"name":"Alice"}' > /tmp/payload.json
awslocal lambda invoke \
  --function-name my-function \
  --payload file:///tmp/payload.json \
  /tmp/output.json && cat /tmp/output.json

# Invoke asynchronously (fire and forget)
awslocal lambda invoke \
  --function-name my-function \
  --invocation-type Event \
  --payload file:///tmp/payload.json \
  /tmp/output.json

# View function logs (after invocation)
awslocal logs filter-log-events \
  --log-group-name /aws/lambda/my-function \
  --limit 20
```

### Aliases & Versions

```bash
# Publish a version (immutable snapshot)
awslocal lambda publish-version --function-name my-function

# List versions
awslocal lambda list-versions-by-function --function-name my-function

# Create alias pointing to a version
awslocal lambda create-alias \
  --function-name my-function \
  --name production \
  --function-version 1

# Update alias to point to new version
awslocal lambda update-alias \
  --function-name my-function \
  --name production \
  --function-version 2
```

### Event Source Mappings (Triggers)

```bash
# Trigger Lambda from SQS
awslocal lambda create-event-source-mapping \
  --function-name my-function \
  --event-source-arn arn:aws:sqs:us-east-1:000000000000:my-queue \
  --batch-size 10

# Trigger Lambda from Kinesis
awslocal lambda create-event-source-mapping \
  --function-name my-function \
  --event-source-arn arn:aws:kinesis:us-east-1:000000000000:stream/my-stream \
  --starting-position LATEST \
  --batch-size 100

# Trigger Lambda from DynamoDB Streams
awslocal lambda create-event-source-mapping \
  --function-name my-function \
  --event-source-arn arn:aws:dynamodb:us-east-1:000000000000:table/Users/stream/... \
  --starting-position LATEST

# List event source mappings
awslocal lambda list-event-source-mappings

# Delete event source mapping
awslocal lambda delete-event-source-mapping --uuid MAPPING_UUID
```

### Concurrency

```bash
# Set reserved concurrency (max parallel instances)
awslocal lambda put-function-concurrency \
  --function-name my-function \
  --reserved-concurrent-executions 10

# Get concurrency settings
awslocal lambda get-function-concurrency --function-name my-function

# Remove reserved concurrency limit
awslocal lambda delete-function-concurrency --function-name my-function
```

---

## 6. EC2 — Elastic Compute Cloud

> Virtual machines in the cloud.
> Key concepts: Instances, AMIs, Security Groups, Key Pairs, EBS Volumes, Elastic IPs.

### Key Pairs

```bash
# Create key pair (save private key)
awslocal ec2 create-key-pair \
  --key-name my-key \
  --query 'KeyMaterial' \
  --output text > my-key.pem
chmod 400 my-key.pem

# List key pairs
awslocal ec2 describe-key-pairs

# Delete key pair
awslocal ec2 delete-key-pair --key-name my-key
```

### Security Groups

```bash
# Create security group
awslocal ec2 create-security-group \
  --group-name web-sg \
  --description "Web server security group"

# Allow inbound HTTP
awslocal ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# Allow inbound HTTPS
awslocal ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# Allow inbound SSH
awslocal ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# List security groups
awslocal ec2 describe-security-groups

# Remove inbound rule
awslocal ec2 revoke-security-group-ingress \
  --group-name web-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# Delete security group
awslocal ec2 delete-security-group --group-name web-sg
```

### Instances

```bash
# Launch instance
awslocal ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t2.micro \
  --key-name my-key \
  --security-groups web-sg \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server}]'

# Launch multiple instances
awslocal ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t2.micro \
  --key-name my-key \
  --count 3

# List all instances
awslocal ec2 describe-instances

# List instances with filter
awslocal ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"

# Get instance IDs only
awslocal ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text

# Stop instance
awslocal ec2 stop-instances --instance-ids i-1234567890abcdef0

# Start instance
awslocal ec2 start-instances --instance-ids i-1234567890abcdef0

# Reboot instance
awslocal ec2 reboot-instances --instance-ids i-1234567890abcdef0

# Terminate (delete) instance
awslocal ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

### AMIs (Images)

```bash
# Create AMI from running instance
awslocal ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "my-app-v1.0" \
  --description "App server AMI"

# List AMIs
awslocal ec2 describe-images --owners self

# Deregister AMI
awslocal ec2 deregister-image --image-id ami-12345678
```

### EBS Volumes

```bash
# Create volume
awslocal ec2 create-volume \
  --size 20 \
  --volume-type gp2 \
  --availability-zone us-east-1a

# Attach volume to instance
awslocal ec2 attach-volume \
  --volume-id vol-1234567890abcdef0 \
  --instance-id i-1234567890abcdef0 \
  --device /dev/sdf

# List volumes
awslocal ec2 describe-volumes

# Detach volume
awslocal ec2 detach-volume --volume-id vol-1234567890abcdef0

# Delete volume
awslocal ec2 delete-volume --volume-id vol-1234567890abcdef0

# Create snapshot (backup of volume)
awslocal ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "backup"

# List snapshots
awslocal ec2 describe-snapshots --owner-ids self
```

### Elastic IPs

```bash
# Allocate Elastic IP
awslocal ec2 allocate-address --domain vpc

# Associate with instance
awslocal ec2 associate-address \
  --instance-id i-1234567890abcdef0 \
  --allocation-id eipalloc-12345678

# Disassociate
awslocal ec2 disassociate-address --association-id eipassoc-12345678

# Release
awslocal ec2 release-address --allocation-id eipalloc-12345678
```

---

## 7. SQS — Simple Queue Service

> Message queue. Decouple services, buffer workloads, retry failures.
> Key concepts: Standard Queue, FIFO Queue, Visibility Timeout, Dead Letter Queue.

### Queues

```bash
# Create standard queue
awslocal sqs create-queue --queue-name my-queue

# Create FIFO queue (ordered, exactly-once delivery)
awslocal sqs create-queue \
  --queue-name my-queue.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true

# Create queue with Dead Letter Queue
DLQ_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $(awslocal sqs get-queue-url --queue-name dlq --query QueueUrl --output text) \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)

awslocal sqs create-queue \
  --queue-name main-queue \
  --attributes "{
    \"VisibilityTimeout\": \"30\",
    \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
  }"

# List all queues
awslocal sqs list-queues

# List queues with prefix
awslocal sqs list-queues --queue-name-prefix my-

# Get queue URL
awslocal sqs get-queue-url --queue-name my-queue

# Get queue attributes
awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/my-queue \
  --attribute-names All

# Delete queue
awslocal sqs delete-queue \
  --queue-url http://localhost:4566/000000000000/my-queue
```

### Messages

```bash
# Set queue URL variable
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name my-queue --query QueueUrl --output text)

# Send a message
awslocal sqs send-message \
  --queue-url $QUEUE_URL \
  --message-body "Hello, World!"

# Send with delay (seconds)
awslocal sqs send-message \
  --queue-url $QUEUE_URL \
  --message-body "Delayed message" \
  --delay-seconds 10

# Send with message attributes
awslocal sqs send-message \
  --queue-url $QUEUE_URL \
  --message-body "Order placed" \
  --message-attributes '{
    "orderId": {"StringValue":"ORD-001","DataType":"String"},
    "amount":  {"StringValue":"99.99","DataType":"Number"}
  }'

# Send batch (up to 10 messages)
awslocal sqs send-message-batch \
  --queue-url $QUEUE_URL \
  --entries '[
    {"Id":"1","MessageBody":"Message 1"},
    {"Id":"2","MessageBody":"Message 2"},
    {"Id":"3","MessageBody":"Message 3"}
  ]'

# Receive messages (returns up to 10)
awslocal sqs receive-message \
  --queue-url $QUEUE_URL \
  --max-number-of-messages 10 \
  --wait-time-seconds 5

# Receive with message attributes
awslocal sqs receive-message \
  --queue-url $QUEUE_URL \
  --message-attribute-names All \
  --max-number-of-messages 5

# Delete message (after processing)
awslocal sqs delete-message \
  --queue-url $QUEUE_URL \
  --receipt-handle "RECEIPT_HANDLE_FROM_RECEIVE"

# Delete messages in batch
awslocal sqs delete-message-batch \
  --queue-url $QUEUE_URL \
  --entries '[
    {"Id":"1","ReceiptHandle":"HANDLE_1"},
    {"Id":"2","ReceiptHandle":"HANDLE_2"}
  ]'

# Change message visibility (extend processing time)
awslocal sqs change-message-visibility \
  --queue-url $QUEUE_URL \
  --receipt-handle "RECEIPT_HANDLE" \
  --visibility-timeout 60

# Purge all messages from queue
awslocal sqs purge-queue --queue-url $QUEUE_URL
```

---

## 8. SNS — Simple Notification Service

> Pub/Sub messaging. Broadcast one message to many subscribers.
> Key concepts: Topics, Subscriptions, Protocols (SQS, Lambda, Email, HTTP), Fan-out.

### Topics

```bash
# Create topic
awslocal sns create-topic --name order-events

# Create FIFO topic
awslocal sns create-topic \
  --name order-events.fifo \
  --attributes FifoTopic=true

# List topics
awslocal sns list-topics

# Get topic ARN
TOPIC_ARN=$(awslocal sns list-topics \
  --query 'Topics[?contains(TopicArn,`order-events`)].TopicArn' \
  --output text)

# Get topic attributes
awslocal sns get-topic-attributes --topic-arn $TOPIC_ARN

# Delete topic
awslocal sns delete-topic --topic-arn $TOPIC_ARN
```

### Subscriptions

```bash
# Subscribe SQS queue to topic
awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:my-queue

# Subscribe Lambda to topic
awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol lambda \
  --notification-endpoint arn:aws:lambda:us-east-1:000000000000:function:my-function

# Subscribe HTTP endpoint
awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol http \
  --notification-endpoint http://myapp.com/webhook

# Subscribe email
awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol email \
  --notification-endpoint user@example.com

# List subscriptions for a topic
awslocal sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN

# List all subscriptions
awslocal sns list-subscriptions

# Unsubscribe
awslocal sns unsubscribe \
  --subscription-arn arn:aws:sns:us-east-1:000000000000:order-events:SUB_ID
```

### Publish Messages

```bash
# Publish simple message
awslocal sns publish \
  --topic-arn $TOPIC_ARN \
  --message "Hello subscribers!"

# Publish with subject
awslocal sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"orderId":"ORD-001","status":"placed"}' \
  --subject "New Order"

# Publish with message attributes (for filtering)
awslocal sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"event":"order_placed"}' \
  --message-attributes '{
    "eventType": {"DataType":"String","StringValue":"order_placed"},
    "region":    {"DataType":"String","StringValue":"US"}
  }'

# Publish to multiple protocols with different formats
awslocal sns publish \
  --topic-arn $TOPIC_ARN \
  --message-structure json \
  --message '{
    "default": "An order was placed",
    "email":   "Dear customer, your order was placed.",
    "sqs":     "{\"orderId\":\"ORD-001\"}"
  }'
```

### Subscription Filtering

```bash
# Set filter policy (only receive matching messages)
awslocal sns set-subscription-attributes \
  --subscription-arn SUBSCRIPTION_ARN \
  --attribute-name FilterPolicy \
  --attribute-value '{"eventType": ["order_placed", "order_shipped"]}'
```

---

## 9. Kinesis

> Real-time data streaming. Process millions of events per second.
> Key concepts: Streams, Shards, Records, Producers, Consumers, Shard Iterator.

### Streams

```bash
# Create stream (1 shard = 1MB/s in, 2MB/s out)
awslocal kinesis create-stream \
  --stream-name clickstream \
  --shard-count 1

# List streams
awslocal kinesis list-streams

# Describe stream
awslocal kinesis describe-stream --stream-name clickstream

# Get stream summary
awslocal kinesis describe-stream-summary --stream-name clickstream

# Add shards (scale up)
awslocal kinesis update-shard-count \
  --stream-name clickstream \
  --target-shard-count 2 \
  --scaling-type UNIFORM_SCALING

# Delete stream
awslocal kinesis delete-stream --stream-name clickstream
```

### Produce Records

```bash
# Put a single record
awslocal kinesis put-record \
  --stream-name clickstream \
  --data '{"userId":"u-001","event":"click","page":"/home"}' \
  --partition-key user-u-001

# Put batch of records (up to 500 at once)
awslocal kinesis put-records \
  --stream-name clickstream \
  --records '[
    {"Data":"{\"userId\":\"u-001\",\"event\":\"click\"}","PartitionKey":"u-001"},
    {"Data":"{\"userId\":\"u-002\",\"event\":\"view\"}","PartitionKey":"u-002"},
    {"Data":"{\"userId\":\"u-003\",\"event\":\"purchase\"}","PartitionKey":"u-003"}
  ]'
```

### Consume Records

```bash
# Get shard iterator (start position)
ITERATOR=$(awslocal kinesis get-shard-iterator \
  --stream-name clickstream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query ShardIterator --output text)
# TRIM_HORIZON = from beginning
# LATEST       = new records only
# AT_TIMESTAMP = from a specific time

# Read records
awslocal kinesis get-records \
  --shard-iterator $ITERATOR \
  --limit 100

# Decode base64 data in records
awslocal kinesis get-records \
  --shard-iterator $ITERATOR | \
  python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
for r in data['Records']:
    print(base64.b64decode(r['Data']).decode())
"

# List shards
awslocal kinesis list-shards --stream-name clickstream
```

---

## 10. CloudFormation

> Infrastructure as Code. Define all your AWS resources in a YAML/JSON template.
> Key concepts: Templates, Stacks, Resources, Parameters, Outputs, Change Sets.

### Stacks

```bash
# Create stack from file
awslocal cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://stack.yaml

# Create stack with parameters
awslocal cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://stack.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=BucketName,ParameterValue=my-prod-bucket

# List stacks
awslocal cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Describe stack
awslocal cloudformation describe-stacks --stack-name my-stack

# Get stack outputs
awslocal cloudformation describe-stacks \
  --stack-name my-stack \
  --query 'Stacks[0].Outputs'

# List resources in a stack
awslocal cloudformation list-stack-resources --stack-name my-stack

# Update stack
awslocal cloudformation update-stack \
  --stack-name my-stack \
  --template-body file://stack-updated.yaml

# Wait for stack to be ready
awslocal cloudformation wait stack-create-complete \
  --stack-name my-stack

# Delete stack (removes all resources)
awslocal cloudformation delete-stack --stack-name my-stack
```

### Change Sets (Preview changes before applying)

```bash
# Create change set
awslocal cloudformation create-change-set \
  --stack-name my-stack \
  --change-set-name my-changes \
  --template-body file://stack-updated.yaml

# Describe change set (see what will change)
awslocal cloudformation describe-change-set \
  --stack-name my-stack \
  --change-set-name my-changes

# Execute change set (apply changes)
awslocal cloudformation execute-change-set \
  --stack-name my-stack \
  --change-set-name my-changes

# Delete change set
awslocal cloudformation delete-change-set \
  --stack-name my-stack \
  --change-set-name my-changes
```

### Template Example

```yaml
# stack.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: My Application Stack

Parameters:
  Environment:
    Type: String
    Default: development
    AllowedValues: [development, staging, production]

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "my-app-${Environment}"

  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub "Users-${Environment}"
      AttributeDefinitions:
        - AttributeName: userId
          AttributeType: S
      KeySchema:
        - AttributeName: userId
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST

  MyQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub "orders-${Environment}"

Outputs:
  BucketName:
    Value: !Ref MyBucket
    Description: S3 Bucket Name
  TableName:
    Value: !Ref MyTable
  QueueUrl:
    Value: !Ref MyQueue
```

---

## 11. STS — Security Token Service

> Get temporary credentials. Used for assuming roles across accounts or services.

```bash
# Get current caller identity
awslocal sts get-caller-identity

# Assume a role (get temporary credentials)
awslocal sts assume-role \
  --role-arn arn:aws:iam::000000000000:role/my-role \
  --role-session-name my-session \
  --duration-seconds 3600

# Assume role with MFA
awslocal sts assume-role \
  --role-arn arn:aws:iam::000000000000:role/my-role \
  --role-session-name my-session \
  --serial-number arn:aws:iam::000000000000:mfa/mydevice \
  --token-code 123456

# Get session token (temporary creds for current user)
awslocal sts get-session-token --duration-seconds 3600

# Decode authorization error messages
awslocal sts decode-authorization-message \
  --encoded-message ENCODED_ERROR_MESSAGE
```

---

## 12. SSM — Parameter Store

> Store config values, secrets, and feature flags securely.
> Key concepts: Parameters, SecureString (encrypted), StringList, Hierarchy.

```bash
# Put a parameter (plain text)
awslocal ssm put-parameter \
  --name "/myapp/db/host" \
  --value "localhost" \
  --type String

# Put a secure parameter (encrypted)
awslocal ssm put-parameter \
  --name "/myapp/db/password" \
  --value "supersecret" \
  --type SecureString

# Put a parameter list
awslocal ssm put-parameter \
  --name "/myapp/allowed-ips" \
  --value "10.0.0.1,10.0.0.2,10.0.0.3" \
  --type StringList

# Get a parameter
awslocal ssm get-parameter --name "/myapp/db/host"

# Get secure parameter (decrypted)
awslocal ssm get-parameter \
  --name "/myapp/db/password" \
  --with-decryption

# Get multiple parameters
awslocal ssm get-parameters \
  --names "/myapp/db/host" "/myapp/db/password" \
  --with-decryption

# Get all parameters by path (prefix)
awslocal ssm get-parameters-by-path \
  --path "/myapp/db/" \
  --recursive \
  --with-decryption

# List all parameters
awslocal ssm describe-parameters

# Update parameter
awslocal ssm put-parameter \
  --name "/myapp/db/host" \
  --value "db.prod.internal" \
  --type String \
  --overwrite

# Delete parameter
awslocal ssm delete-parameter --name "/myapp/db/host"

# Delete multiple parameters
awslocal ssm delete-parameters \
  --names "/myapp/db/host" "/myapp/db/password"
```

---

## 13. Secrets Manager

> Store and rotate credentials (DB passwords, API keys).
> Key concepts: Secrets, Versions, Rotation, Automatic rotation.

```bash
# Create a secret (plain text)
awslocal secretsmanager create-secret \
  --name "myapp/db-password" \
  --secret-string "SuperSecret123!"

# Create a secret (key-value JSON)
awslocal secretsmanager create-secret \
  --name "myapp/db-credentials" \
  --secret-string '{"username":"admin","password":"Secret123!","host":"localhost"}'

# Get secret value
awslocal secretsmanager get-secret-value \
  --secret-id "myapp/db-credentials"

# Get secret value (just the string)
awslocal secretsmanager get-secret-value \
  --secret-id "myapp/db-credentials" \
  --query SecretString --output text

# List secrets
awslocal secretsmanager list-secrets

# Describe secret (metadata, no value)
awslocal secretsmanager describe-secret \
  --secret-id "myapp/db-credentials"

# Update secret value
awslocal secretsmanager update-secret \
  --secret-id "myapp/db-credentials" \
  --secret-string '{"username":"admin","password":"NewSecret456!"}'

# Rotate secret (creates new version)
awslocal secretsmanager rotate-secret \
  --secret-id "myapp/db-credentials"

# Delete secret (with 7-day recovery window)
awslocal secretsmanager delete-secret \
  --secret-id "myapp/db-credentials"

# Delete secret immediately (no recovery)
awslocal secretsmanager delete-secret \
  --secret-id "myapp/db-credentials" \
  --force-delete-without-recovery
```

---

## 14. CloudWatch

> Monitoring, logs, metrics, and alarms for all AWS services.
> Key concepts: Log Groups, Log Streams, Metrics, Alarms, Dashboards.

### Logs

```bash
# Create log group
awslocal logs create-log-group --log-group-name /myapp/api

# Create log stream inside a group
awslocal logs create-log-stream \
  --log-group-name /myapp/api \
  --log-stream-name server-1

# Put log events
awslocal logs put-log-events \
  --log-group-name /myapp/api \
  --log-stream-name server-1 \
  --log-events '[
    {"timestamp":1700000000000,"message":"Server started"},
    {"timestamp":1700000001000,"message":"Request received: GET /health"}
  ]'

# Get log events
awslocal logs get-log-events \
  --log-group-name /myapp/api \
  --log-stream-name server-1 \
  --limit 50

# Filter/search logs
awslocal logs filter-log-events \
  --log-group-name /myapp/api \
  --filter-pattern "ERROR"

# Filter logs by time range
awslocal logs filter-log-events \
  --log-group-name /myapp/api \
  --start-time 1700000000000 \
  --end-time 1700003600000

# List log groups
awslocal logs describe-log-groups

# List log streams in a group
awslocal logs describe-log-streams \
  --log-group-name /myapp/api

# Set retention policy (auto-delete after N days)
awslocal logs put-retention-policy \
  --log-group-name /myapp/api \
  --retention-in-days 30

# Delete log group
awslocal logs delete-log-group --log-group-name /myapp/api
```

### Metrics & Alarms

```bash
# Put a custom metric
awslocal cloudwatch put-metric-data \
  --namespace "MyApp" \
  --metric-data '[{
    "MetricName": "OrdersPlaced",
    "Value": 1,
    "Unit": "Count",
    "Dimensions": [{"Name":"Environment","Value":"production"}]
  }]'

# Get metric statistics
awslocal cloudwatch get-metric-statistics \
  --namespace "MyApp" \
  --metric-name "OrdersPlaced" \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# List metrics
awslocal cloudwatch list-metrics --namespace "MyApp"

# Create alarm
awslocal cloudwatch put-metric-alarm \
  --alarm-name "HighErrorRate" \
  --metric-name "Errors" \
  --namespace "MyApp" \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:000000000000:alerts

# List alarms
awslocal cloudwatch describe-alarms

# Get alarm state
awslocal cloudwatch describe-alarms \
  --alarm-names "HighErrorRate" \
  --query 'MetricAlarms[0].StateValue'

# Delete alarm
awslocal cloudwatch delete-alarms --alarm-names "HighErrorRate"
```

---

## Quick Reference — Data Types (DynamoDB)

| Type | Symbol | Example |
|------|--------|---------|
| String | `S` | `{"S": "hello"}` |
| Number | `N` | `{"N": "42"}` |
| Boolean | `BOOL` | `{"BOOL": true}` |
| List | `L` | `{"L": [{"S":"a"},{"S":"b"}]}` |
| Map | `M` | `{"M": {"key":{"S":"val"}}}` |
| Null | `NULL` | `{"NULL": true}` |
| Binary | `B` | `{"B": "aGVsbG8="}` |
| String Set | `SS` | `{"SS": ["a","b","c"]}` |
| Number Set | `NS` | `{"NS": ["1","2","3"]}` |

---

## Quick Reference — Common AWS ARN Formats (LocalStack)

```
IAM User:    arn:aws:iam::000000000000:user/alice
IAM Role:    arn:aws:iam::000000000000:role/lambda-exec-role
S3 Bucket:   arn:aws:s3:::my-bucket
S3 Object:   arn:aws:s3:::my-bucket/path/file.txt
DynamoDB:    arn:aws:dynamodb:us-east-1:000000000000:table/Users
Lambda:      arn:aws:lambda:us-east-1:000000000000:function:my-function
SQS:         arn:aws:sqs:us-east-1:000000000000:my-queue
SNS:         arn:aws:sns:us-east-1:000000000000:order-events
Kinesis:     arn:aws:kinesis:us-east-1:000000000000:stream/clickstream
```

# AWS Learning Plan — End to End (with LocalStack)

All projects run locally using `awslocal` on `http://localhost:4566`.
Progress through each phase in order — each builds on the previous.

---

## Phase 1 — Foundations (Week 1)

### Module 1: IAM (Identity & Access Management)
**Learn:** Users, Groups, Roles, Policies, Permissions

**Project:** Create a user with limited S3 access only
```bash
awslocal iam create-user --user-name dev-user
awslocal iam create-group --group-name developers
awslocal iam add-user-to-group --user-name dev-user --group-name developers
awslocal iam attach-group-policy --group-name developers \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
awslocal iam list-users
```

---

### Module 2: S3 (Simple Storage Service)
**Learn:** Buckets, Objects, Versioning, Lifecycle, Permissions

**Project 1 — Basic upload/download:**
```bash
awslocal s3 mb s3://my-app-bucket
echo "Hello AWS" > hello.txt
awslocal s3 cp hello.txt s3://my-app-bucket/
awslocal s3 ls s3://my-app-bucket
awslocal s3 cp s3://my-app-bucket/hello.txt downloaded.txt
```

**Project 2 — Versioning:**
```bash
awslocal s3api put-bucket-versioning \
  --bucket my-app-bucket \
  --versioning-configuration Status=Enabled
echo "Version 1" > file.txt && awslocal s3 cp file.txt s3://my-app-bucket/
echo "Version 2" > file.txt && awslocal s3 cp file.txt s3://my-app-bucket/
awslocal s3api list-object-versions --bucket my-app-bucket
```

**Project 3 — Static website hosting:**
```bash
awslocal s3 mb s3://my-website
echo "<h1>My Local Website</h1>" > index.html
awslocal s3 cp index.html s3://my-website/
awslocal s3 website s3://my-website/ --index-document index.html
```

---

## Phase 2 — Databases (Week 2)

### Module 3: DynamoDB (NoSQL Database)
**Learn:** Tables, Items, Keys, Indexes, Queries, Scans

**Project 1 — Create and query a users table:**
```bash
awslocal dynamodb create-table \
  --table-name Users \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

awslocal dynamodb put-item --table-name Users \
  --item '{"userId":{"S":"1"},"name":{"S":"Alice"},"age":{"N":"30"}}'

awslocal dynamodb put-item --table-name Users \
  --item '{"userId":{"S":"2"},"name":{"S":"Bob"},"age":{"N":"25"}}'

awslocal dynamodb get-item --table-name Users \
  --key '{"userId":{"S":"1"}}'

awslocal dynamodb scan --table-name Users
```

**Project 2 — E-commerce orders table with GSI:**
```bash
awslocal dynamodb create-table \
  --table-name Orders \
  --attribute-definitions \
    AttributeName=orderId,AttributeType=S \
    AttributeName=customerId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --global-secondary-indexes \
    '[{"IndexName":"CustomerIndex","KeySchema":[{"AttributeName":"customerId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"},"ProvisionedThroughput":{"ReadCapacityUnits":5,"WriteCapacityUnits":5}}]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

awslocal dynamodb put-item --table-name Orders \
  --item '{"orderId":{"S":"ORD-001"},"customerId":{"S":"CUST-1"},"amount":{"N":"99.99"},"status":{"S":"PENDING"}}'

awslocal dynamodb query --table-name Orders \
  --index-name CustomerIndex \
  --key-condition-expression "customerId = :cid" \
  --expression-attribute-values '{":cid":{"S":"CUST-1"}}'
```

---

### Module 4: RDS (Relational Database)
**Learn:** Instances, Snapshots, Parameter Groups, Subnets

**Project — Create a Postgres RDS instance:**
```bash
awslocal rds create-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password password123 \
  --allocated-storage 20

awslocal rds describe-db-instances
```

---

## Phase 3 — Compute (Week 3)

### Module 5: Lambda (Serverless Functions)
**Learn:** Functions, Triggers, Layers, Environment Variables, Invocations

**Project 1 — Hello World function:**
```bash
# Create handler.py
cat > handler.py << 'EOF'
import json
def lambda_handler(event, context):
    name = event.get('name', 'World')
    return {'statusCode': 200, 'body': json.dumps(f'Hello, {name}!')}
EOF

zip function.zip handler.py

awslocal lambda create-function \
  --function-name hello-world \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip

awslocal lambda invoke \
  --function-name hello-world \
  --payload '{"name":"Alice"}' \
  output.json && cat output.json
```

**Project 2 — Lambda that reads/writes S3:**
```bash
cat > s3_handler.py << 'EOF'
import boto3, json, os
s3 = boto3.client('s3', endpoint_url='http://localhost:4566')
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    s3.put_object(Bucket=BUCKET, Key='result.json', Body=json.dumps(event))
    return {'status': 'saved'}
EOF

zip s3_function.zip s3_handler.py

awslocal lambda create-function \
  --function-name s3-writer \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler s3_handler.lambda_handler \
  --zip-file fileb://s3_function.zip \
  --environment Variables="{BUCKET_NAME=my-app-bucket}"

awslocal lambda invoke \
  --function-name s3-writer \
  --payload '{"message":"hello from lambda"}' \
  out.json
```

---

### Module 6: EC2 (Virtual Machines)
**Learn:** Instances, AMIs, Security Groups, Key Pairs, EBS

**Project — Launch and describe an EC2 instance:**
```bash
awslocal ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem

awslocal ec2 create-security-group \
  --group-name web-sg \
  --description "Web server security group"

awslocal ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

awslocal ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t2.micro \
  --key-name my-key \
  --security-groups web-sg \
  --count 1

awslocal ec2 describe-instances
```

---

## Phase 4 — Messaging (Week 4)

### Module 7: SQS (Simple Queue Service)
**Learn:** Standard Queues, FIFO Queues, Dead Letter Queues, Visibility Timeout

**Project 1 — Send and receive messages:**
```bash
awslocal sqs create-queue --queue-name my-queue
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name my-queue --query QueueUrl --output text)

awslocal sqs send-message --queue-url $QUEUE_URL --message-body "Order #001 placed"
awslocal sqs send-message --queue-url $QUEUE_URL --message-body "Order #002 placed"

awslocal sqs receive-message --queue-url $QUEUE_URL --max-number-of-messages 2
```

**Project 2 — Dead Letter Queue:**
```bash
awslocal sqs create-queue --queue-name dead-letter-queue
DLQ_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $(awslocal sqs get-queue-url --queue-name dead-letter-queue --query QueueUrl --output text) \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)

awslocal sqs create-queue --queue-name main-queue \
  --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
```

---

### Module 8: SNS (Simple Notification Service)
**Learn:** Topics, Subscriptions, Fan-out pattern, Filtering

**Project — SNS topic that triggers SQS + Lambda:**
```bash
awslocal sns create-topic --name order-events
TOPIC_ARN=$(awslocal sns list-topics --query 'Topics[0].TopicArn' --output text)

# Subscribe SQS to SNS
QUEUE_URL=$(awslocal sqs create-queue --queue-name order-queue --query QueueUrl --output text)
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $QUEUE_URL --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $QUEUE_ARN

# Publish an event — all subscribers receive it
awslocal sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"event":"order_placed","orderId":"ORD-001"}' \
  --subject "New Order"

# Check SQS received it
awslocal sqs receive-message --queue-url $QUEUE_URL
```

---

## Phase 5 — Advanced (Week 5)

### Module 9: Lambda + SQS + S3 (Full Pipeline)
**Project — Order processing pipeline:**
```
User → SNS → SQS → Lambda → DynamoDB + S3
```
```bash
# 1. Create resources
awslocal s3 mb s3://order-receipts
awslocal dynamodb create-table \
  --table-name ProcessedOrders \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 2. Create Lambda that processes SQS messages
cat > order_processor.py << 'EOF'
import boto3, json, os

dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
s3 = boto3.client('s3', endpoint_url='http://localhost:4566')
table = dynamodb.Table('ProcessedOrders')

def lambda_handler(event, context):
    for record in event['Records']:
        order = json.loads(record['body'])
        table.put_item(Item={'orderId': order['orderId'], 'status': 'PROCESSED'})
        s3.put_object(
            Bucket='order-receipts',
            Key=f"receipts/{order['orderId']}.json",
            Body=json.dumps(order)
        )
    return {'processed': len(event['Records'])}
EOF
```

---

### Module 10: Kinesis (Data Streaming)
**Learn:** Streams, Shards, Producers, Consumers

**Project — Real-time event stream:**
```bash
awslocal kinesis create-stream --stream-name clickstream --shard-count 1

awslocal kinesis put-record \
  --stream-name clickstream \
  --data '{"userId":"u1","event":"click","page":"/home"}' \
  --partition-key user1

SHARD_ITERATOR=$(awslocal kinesis get-shard-iterator \
  --stream-name clickstream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query ShardIterator --output text)

awslocal kinesis get-records --shard-iterator $SHARD_ITERATOR
```

---

### Module 11: CloudFormation (Infrastructure as Code)
**Learn:** Templates, Stacks, Resources, Outputs, Parameters

**Project — Deploy full stack via template:**
```bash
cat > stack.yaml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: cfn-demo-bucket
  MyQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: cfn-demo-queue
  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: cfn-demo-table
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
Outputs:
  BucketName:
    Value: !Ref MyBucket
  QueueUrl:
    Value: !Ref MyQueue
EOF

awslocal cloudformation create-stack \
  --stack-name my-app-stack \
  --template-body file://stack.yaml

awslocal cloudformation describe-stacks --stack-name my-app-stack
```

---

## Learning Checklist

- [ ] **Phase 1** — IAM + S3
- [ ] **Phase 2** — DynamoDB + RDS
- [ ] **Phase 3** — Lambda + EC2
- [ ] **Phase 4** — SQS + SNS
- [ ] **Phase 5** — Kinesis + CloudFormation + Full Pipeline

---

## Capstone Project — Mini E-commerce Backend

Build a complete backend using all services:

```
API Request
    │
    ▼
Lambda (handler)
    │
    ├──► DynamoDB (store order)
    ├──► S3 (store invoice PDF)
    └──► SNS (order-events topic)
              │
              ├──► SQS (email-queue) ──► Lambda (send email)
              └──► SQS (inventory-queue) ──► Lambda (update stock)
```

All infrastructure deployed via CloudFormation.

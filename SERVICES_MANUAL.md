# AWS Services Manual

A complete reference for all 57 AWS services in this project, each with a standalone demo and detailed README.

## Quick Start

```bash
# Start LocalStack
docker-compose up -d

# Activate venv
source .venv/bin/activate
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Run ALL service demos
bash run-all.sh

# Run a single service demo
bash services/01-compute/lambda/demo.sh

# Clean up everything
bash teardown-all.sh
```

---

## Services by Category


### COMPUTE

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `lambda` | AWS Lambda | [README](services/01-compute/lambda/README.md) | [demo.sh](services/01-compute/lambda/demo.sh) |
| `ec2` | Amazon EC2 | [README](services/01-compute/ec2/README.md) | [demo.sh](services/01-compute/ec2/demo.sh) |
| `ecs` | Amazon ECS | [README](services/01-compute/ecs/README.md) | [demo.sh](services/01-compute/ecs/demo.sh) |
| `ecr` | Amazon ECR | [README](services/01-compute/ecr/README.md) | [demo.sh](services/01-compute/ecr/demo.sh) |
| `batch` | AWS Batch | [README](services/01-compute/batch/README.md) | [demo.sh](services/01-compute/batch/demo.sh) |


### STORAGE

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `s3` | Amazon S3 | [README](services/02-storage/s3/README.md) | [demo.sh](services/02-storage/s3/demo.sh) |
| `glacier` | Amazon S3 Glacier | [README](services/02-storage/glacier/README.md) | [demo.sh](services/02-storage/glacier/demo.sh) |
| `s3control` | Amazon S3 Control | [README](services/02-storage/s3control/README.md) | [demo.sh](services/02-storage/s3control/demo.sh) |


### DATABASE

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `dynamodb` | Amazon DynamoDB | [README](services/03-database/dynamodb/README.md) | [demo.sh](services/03-database/dynamodb/demo.sh) |
| `rds` | Amazon RDS | [README](services/03-database/rds/README.md) | [demo.sh](services/03-database/rds/demo.sh) |
| `elasticache` | Amazon ElastiCache | [README](services/03-database/elasticache/README.md) | [demo.sh](services/03-database/elasticache/demo.sh) |
| `redshift` | Amazon Redshift | [README](services/03-database/redshift/README.md) | [demo.sh](services/03-database/redshift/demo.sh) |
| `neptune` | Amazon Neptune | [README](services/03-database/neptune/README.md) | [demo.sh](services/03-database/neptune/demo.sh) |
| `qldb` | Amazon QLDB | [README](services/03-database/qldb/README.md) | [demo.sh](services/03-database/qldb/demo.sh) |
| `timestream` | Amazon Timestream | [README](services/03-database/timestream/README.md) | [demo.sh](services/03-database/timestream/demo.sh) |
| `docdb` | Amazon DocumentDB | [README](services/03-database/docdb/README.md) | [demo.sh](services/03-database/docdb/demo.sh) |


### MESSAGING

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `sqs` | Amazon SQS | [README](services/04-messaging/sqs/README.md) | [demo.sh](services/04-messaging/sqs/demo.sh) |
| `sns` | Amazon SNS | [README](services/04-messaging/sns/README.md) | [demo.sh](services/04-messaging/sns/demo.sh) |
| `kinesis` | Amazon Kinesis | [README](services/04-messaging/kinesis/README.md) | [demo.sh](services/04-messaging/kinesis/demo.sh) |
| `firehose` | Amazon Kinesis Firehose | [README](services/04-messaging/firehose/README.md) | [demo.sh](services/04-messaging/firehose/demo.sh) |
| `eventbridge` | Amazon EventBridge | [README](services/04-messaging/eventbridge/README.md) | [demo.sh](services/04-messaging/eventbridge/demo.sh) |
| `mq` | Amazon MQ | [README](services/04-messaging/mq/README.md) | [demo.sh](services/04-messaging/mq/demo.sh) |
| `msk` | Amazon MSK | [README](services/04-messaging/msk/README.md) | [demo.sh](services/04-messaging/msk/demo.sh) |


### NETWORKING

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `route53` | Amazon Route 53 | [README](services/05-networking/route53/README.md) | [demo.sh](services/05-networking/route53/demo.sh) |
| `apigateway` | Amazon API Gateway | [README](services/05-networking/apigateway/README.md) | [demo.sh](services/05-networking/apigateway/demo.sh) |
| `cloudfront` | Amazon CloudFront | [README](services/05-networking/cloudfront/README.md) | [demo.sh](services/05-networking/cloudfront/demo.sh) |
| `waf` | AWS WAF | [README](services/05-networking/waf/README.md) | [demo.sh](services/05-networking/waf/demo.sh) |
| `elb` | Elastic Load Balancing | [README](services/05-networking/elb/README.md) | [demo.sh](services/05-networking/elb/demo.sh) |


### SECURITY

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `iam` | AWS IAM | [README](services/06-security/iam/README.md) | [demo.sh](services/06-security/iam/demo.sh) |
| `kms` | AWS KMS | [README](services/06-security/kms/README.md) | [demo.sh](services/06-security/kms/demo.sh) |
| `secretsmanager` | AWS Secrets Manager | [README](services/06-security/secretsmanager/README.md) | [demo.sh](services/06-security/secretsmanager/demo.sh) |
| `acm` | AWS ACM | [README](services/06-security/acm/README.md) | [demo.sh](services/06-security/acm/demo.sh) |
| `cognito-idp` | Amazon Cognito User Pools | [README](services/06-security/cognito-idp/README.md) | [demo.sh](services/06-security/cognito-idp/demo.sh) |
| `cognito-identity` | Amazon Cognito Identity | [README](services/06-security/cognito-identity/README.md) | [demo.sh](services/06-security/cognito-identity/demo.sh) |
| `sts` | AWS STS | [README](services/06-security/sts/README.md) | [demo.sh](services/06-security/sts/demo.sh) |


### MONITORING

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `cloudwatch` | Amazon CloudWatch | [README](services/07-monitoring/cloudwatch/README.md) | [demo.sh](services/07-monitoring/cloudwatch/demo.sh) |
| `cloudwatch-logs` | Amazon CloudWatch Logs | [README](services/07-monitoring/cloudwatch-logs/README.md) | [demo.sh](services/07-monitoring/cloudwatch-logs/demo.sh) |
| `cloudtrail` | AWS CloudTrail | [README](services/07-monitoring/cloudtrail/README.md) | [demo.sh](services/07-monitoring/cloudtrail/demo.sh) |
| `xray` | AWS X-Ray | [README](services/07-monitoring/xray/README.md) | [demo.sh](services/07-monitoring/xray/demo.sh) |


### MANAGEMENT

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `cloudformation` | AWS CloudFormation | [README](services/08-management/cloudformation/README.md) | [demo.sh](services/08-management/cloudformation/demo.sh) |
| `ssm` | AWS Systems Manager | [README](services/08-management/ssm/README.md) | [demo.sh](services/08-management/ssm/demo.sh) |
| `appconfig` | AWS AppConfig | [README](services/08-management/appconfig/README.md) | [demo.sh](services/08-management/appconfig/demo.sh) |
| `config` | AWS Config | [README](services/08-management/config/README.md) | [demo.sh](services/08-management/config/demo.sh) |


### DEVTOOLS

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `codecommit` | AWS CodeCommit | [README](services/09-devtools/codecommit/README.md) | [demo.sh](services/09-devtools/codecommit/demo.sh) |
| `codebuild` | AWS CodeBuild | [README](services/09-devtools/codebuild/README.md) | [demo.sh](services/09-devtools/codebuild/demo.sh) |
| `codedeploy` | AWS CodeDeploy | [README](services/09-devtools/codedeploy/README.md) | [demo.sh](services/09-devtools/codedeploy/demo.sh) |
| `codepipeline` | AWS CodePipeline | [README](services/09-devtools/codepipeline/README.md) | [demo.sh](services/09-devtools/codepipeline/demo.sh) |


### ANALYTICS

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `athena` | Amazon Athena | [README](services/10-analytics/athena/README.md) | [demo.sh](services/10-analytics/athena/demo.sh) |
| `glue` | AWS Glue | [README](services/10-analytics/glue/README.md) | [demo.sh](services/10-analytics/glue/demo.sh) |
| `emr` | Amazon EMR | [README](services/10-analytics/emr/README.md) | [demo.sh](services/10-analytics/emr/demo.sh) |
| `opensearch` | Amazon OpenSearch | [README](services/10-analytics/opensearch/README.md) | [demo.sh](services/10-analytics/opensearch/demo.sh) |


### INTEGRATION

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
| `stepfunctions` | AWS Step Functions | [README](services/11-integration/stepfunctions/README.md) | [demo.sh](services/11-integration/stepfunctions/demo.sh) |
| `ses` | Amazon SES | [README](services/11-integration/ses/README.md) | [demo.sh](services/11-integration/ses/demo.sh) |
| `transfer` | AWS Transfer Family | [README](services/11-integration/transfer/README.md) | [demo.sh](services/11-integration/transfer/demo.sh) |
| `iot` | AWS IoT Core | [README](services/11-integration/iot/README.md) | [demo.sh](services/11-integration/iot/demo.sh) |
| `appsync` | AWS AppSync | [README](services/11-integration/appsync/README.md) | [demo.sh](services/11-integration/appsync/demo.sh) |
| `swf` | Amazon SWF | [README](services/11-integration/swf/README.md) | [demo.sh](services/11-integration/swf/demo.sh) |


---

## Service Cheat Sheet

| Service | CLI Prefix | Create | List | Delete |
|---------|-----------|--------|------|--------|
| S3 | `s3` | `mb s3://name` | `ls` | `rb s3://name` |
| DynamoDB | `dynamodb` | `create-table` | `list-tables` | `delete-table` |
| SQS | `sqs` | `create-queue` | `list-queues` | `delete-queue` |
| SNS | `sns` | `create-topic` | `list-topics` | `delete-topic` |
| Lambda | `lambda` | `create-function` | `list-functions` | `delete-function` |
| Kinesis | `kinesis` | `create-stream` | `list-streams` | `delete-stream` |
| IAM | `iam` | `create-user` | `list-users` | `delete-user` |
| KMS | `kms` | `create-key` | `list-keys` | `schedule-key-deletion` |
| Secrets Manager | `secretsmanager` | `create-secret` | `list-secrets` | `delete-secret` |
| CloudWatch | `cloudwatch` | `put-metric-data` | `list-metrics` | `delete-alarms` |
| CloudWatch Logs | `logs` | `create-log-group` | `describe-log-groups` | `delete-log-group` |
| StepFunctions | `stepfunctions` | `create-state-machine` | `list-state-machines` | `delete-state-machine` |
| SSM | `ssm` | `put-parameter` | `describe-parameters` | `delete-parameter` |
| EC2 | `ec2` | `run-instances` | `describe-instances` | `terminate-instances` |
| ECR | `ecr` | `create-repository` | `describe-repositories` | `delete-repository` |
| ECS | `ecs` | `create-cluster` | `list-clusters` | `delete-cluster` |
| RDS | `rds` | `create-db-instance` | `describe-db-instances` | `delete-db-instance` |
| Route53 | `route53` | `create-hosted-zone` | `list-hosted-zones` | `delete-hosted-zone` |
| API Gateway | `apigateway` | `create-rest-api` | `get-rest-apis` | `delete-rest-api` |
| Cognito IDP | `cognito-idp` | `create-user-pool` | `list-user-pools` | `delete-user-pool` |
| EventBridge | `events` | `create-event-bus` | `list-event-buses` | `delete-event-bus` |
| Athena | `athena` | `create-work-group` | `list-work-groups` | `delete-work-group` |
| Glue | `glue` | `create-database` | `get-databases` | `delete-database` |
| SES | `ses` | `verify-email-identity` | `list-identities` | `delete-identity` |
| CodeCommit | `codecommit` | `create-repository` | `list-repositories` | `delete-repository` |
| STS | `sts` | — | `get-caller-identity` | — |

---

## Project Structure

```
aws/
├── services/
│   ├── 01-compute/         (lambda, ec2, ecs, ecr, batch)
│   ├── 02-storage/         (s3, glacier, s3control)
│   ├── 03-database/        (dynamodb, rds, elasticache, redshift, neptune, qldb, timestream, docdb)
│   ├── 04-messaging/       (sqs, sns, kinesis, firehose, eventbridge, mq, msk)
│   ├── 05-networking/      (route53, apigateway, cloudfront, waf, elb)
│   ├── 06-security/        (iam, kms, secretsmanager, acm, cognito-idp, cognito-identity, sts)
│   ├── 07-monitoring/      (cloudwatch, cloudwatch-logs, cloudtrail, xray)
│   ├── 08-management/      (cloudformation, ssm, appconfig, config)
│   ├── 09-devtools/        (codecommit, codebuild, codedeploy, codepipeline)
│   ├── 10-analytics/       (athena, glue, emr, opensearch)
│   └── 11-integration/     (stepfunctions, ses, transfer, iot, appsync, swf)
├── ecommerce/              (multi-service project using 8+ services together)
├── run-all.sh              (run every demo)
├── teardown-all.sh         (delete all resources)
├── SERVICES_MANUAL.md      (this file)
├── docker-compose.yml
└── .venv/
```


export const meta = {
  name: 'aws-services-manuals',
  description: 'Generate README.md manual for every AWS service demo directory',
  phases: [
    { title: 'Generate Manuals', detail: 'Write README.md for each service in parallel' },
    { title: 'Write Files', detail: 'Save all manuals to disk' },
    { title: 'Master Manual', detail: 'Write the combined SERVICES_MANUAL.md' },
  ],
}

const BASE = '/Volumes/storage/aws/services'

const CATEGORIES = [
  {
    dir: '01-compute',
    services: [
      { name: 'lambda',   full: 'AWS Lambda',             group: 'Compute' },
      { name: 'ec2',      full: 'Amazon EC2',              group: 'Compute' },
      { name: 'ecs',      full: 'Amazon ECS',              group: 'Compute' },
      { name: 'ecr',      full: 'Amazon ECR',              group: 'Compute' },
      { name: 'batch',    full: 'AWS Batch',               group: 'Compute' },
    ],
  },
  {
    dir: '02-storage',
    services: [
      { name: 's3',        full: 'Amazon S3',              group: 'Storage' },
      { name: 'glacier',   full: 'Amazon S3 Glacier',      group: 'Storage' },
      { name: 's3control', full: 'Amazon S3 Control',      group: 'Storage' },
    ],
  },
  {
    dir: '03-database',
    services: [
      { name: 'dynamodb',    full: 'Amazon DynamoDB',      group: 'Database' },
      { name: 'rds',         full: 'Amazon RDS',           group: 'Database' },
      { name: 'elasticache', full: 'Amazon ElastiCache',   group: 'Database' },
      { name: 'redshift',    full: 'Amazon Redshift',      group: 'Database' },
      { name: 'neptune',     full: 'Amazon Neptune',       group: 'Database' },
      { name: 'qldb',        full: 'Amazon QLDB',          group: 'Database' },
      { name: 'timestream',  full: 'Amazon Timestream',    group: 'Database' },
      { name: 'docdb',       full: 'Amazon DocumentDB',    group: 'Database' },
    ],
  },
  {
    dir: '04-messaging',
    services: [
      { name: 'sqs',         full: 'Amazon SQS',           group: 'Messaging' },
      { name: 'sns',         full: 'Amazon SNS',           group: 'Messaging' },
      { name: 'kinesis',     full: 'Amazon Kinesis',       group: 'Messaging' },
      { name: 'firehose',    full: 'Amazon Kinesis Firehose', group: 'Messaging' },
      { name: 'eventbridge', full: 'Amazon EventBridge',   group: 'Messaging' },
      { name: 'mq',          full: 'Amazon MQ',            group: 'Messaging' },
      { name: 'msk',         full: 'Amazon MSK',           group: 'Messaging' },
    ],
  },
  {
    dir: '05-networking',
    services: [
      { name: 'route53',    full: 'Amazon Route 53',       group: 'Networking' },
      { name: 'apigateway', full: 'Amazon API Gateway',    group: 'Networking' },
      { name: 'cloudfront', full: 'Amazon CloudFront',     group: 'Networking' },
      { name: 'waf',        full: 'AWS WAF',               group: 'Networking' },
      { name: 'elb',        full: 'Elastic Load Balancing',group: 'Networking' },
    ],
  },
  {
    dir: '06-security',
    services: [
      { name: 'iam',              full: 'AWS IAM',                  group: 'Security' },
      { name: 'kms',              full: 'AWS KMS',                  group: 'Security' },
      { name: 'secretsmanager',   full: 'AWS Secrets Manager',      group: 'Security' },
      { name: 'acm',              full: 'AWS ACM',                  group: 'Security' },
      { name: 'cognito-idp',      full: 'Amazon Cognito User Pools',group: 'Security' },
      { name: 'cognito-identity', full: 'Amazon Cognito Identity',  group: 'Security' },
      { name: 'sts',              full: 'AWS STS',                  group: 'Security' },
    ],
  },
  {
    dir: '07-monitoring',
    services: [
      { name: 'cloudwatch',      full: 'Amazon CloudWatch',         group: 'Monitoring' },
      { name: 'cloudwatch-logs', full: 'Amazon CloudWatch Logs',    group: 'Monitoring' },
      { name: 'cloudtrail',      full: 'AWS CloudTrail',            group: 'Monitoring' },
      { name: 'xray',            full: 'AWS X-Ray',                 group: 'Monitoring' },
    ],
  },
  {
    dir: '08-management',
    services: [
      { name: 'cloudformation', full: 'AWS CloudFormation', group: 'Management' },
      { name: 'ssm',            full: 'AWS Systems Manager',group: 'Management' },
      { name: 'appconfig',      full: 'AWS AppConfig',      group: 'Management' },
      { name: 'config',         full: 'AWS Config',         group: 'Management' },
    ],
  },
  {
    dir: '09-devtools',
    services: [
      { name: 'codecommit',  full: 'AWS CodeCommit',  group: 'DevTools' },
      { name: 'codebuild',   full: 'AWS CodeBuild',   group: 'DevTools' },
      { name: 'codedeploy',  full: 'AWS CodeDeploy',  group: 'DevTools' },
      { name: 'codepipeline',full: 'AWS CodePipeline',group: 'DevTools' },
    ],
  },
  {
    dir: '10-analytics',
    services: [
      { name: 'athena',     full: 'Amazon Athena',          group: 'Analytics' },
      { name: 'glue',       full: 'AWS Glue',               group: 'Analytics' },
      { name: 'emr',        full: 'Amazon EMR',             group: 'Analytics' },
      { name: 'opensearch', full: 'Amazon OpenSearch',      group: 'Analytics' },
    ],
  },
  {
    dir: '11-integration',
    services: [
      { name: 'stepfunctions', full: 'AWS Step Functions', group: 'Integration' },
      { name: 'ses',           full: 'Amazon SES',         group: 'Integration' },
      { name: 'transfer',      full: 'AWS Transfer Family',group: 'Integration' },
      { name: 'iot',           full: 'AWS IoT Core',       group: 'Integration' },
      { name: 'appsync',       full: 'AWS AppSync',        group: 'Integration' },
      { name: 'swf',           full: 'Amazon SWF',         group: 'Integration' },
    ],
  },
]

phase('Generate Manuals')

const manuals = await parallel(CATEGORIES.map(cat => () =>
  agent(
    `Write a clear, concise README.md manual for EACH of these AWS services: ${cat.services.map(s => s.full).join(', ')}

For EACH service write a README.md with these exact sections:

# <Service Full Name>

## What is it?
One paragraph (3-4 sentences) explaining what the service does, when to use it, and its main benefit.

## Key Concepts
Bullet list of 4-6 core concepts/terms for this service (e.g. for S3: Bucket, Object, Key, ACL, Versioning).

## When to Use
3-4 bullet points describing real use cases.

## CLI Quick Reference (awslocal)
A table or code blocks showing the most important CLI commands. Use awslocal. Cover: create, list, read/get, update, delete operations. Include realistic example values.

## Example Walkthrough
A step-by-step example (numbered steps, each with the awslocal command and a one-line explanation of what it does).
Show at least 5 steps.

## Important Flags & Options
A table of the most commonly used flags/parameters for this service.

## How to Run the Demo
\`\`\`bash
cd services/${cat.dir}/<service-name>
bash demo.sh
\`\`\`

---
Keep each README.md practical and beginner-friendly. Use real AWS terminology. All commands use awslocal.

Return a JSON object: keys are the short service name (e.g. "lambda", "ec2"), values are the full README.md content as a string.

Services: ${cat.services.map(s => s.name).join(', ')}`,
    {
      label: `manual:${cat.dir}`,
      phase: 'Generate Manuals',
      schema: {
        type: 'object',
        description: 'Map of service name to README.md content',
        additionalProperties: { type: 'string' },
      },
    }
  ).then(readmes => ({ cat, readmes }))
))

phase('Write Files')

await parallel(manuals.filter(Boolean).flatMap(({ cat, readmes }) =>
  Object.entries(readmes).map(([service, content]) => () =>
    agent(
      `Write a file to disk.

Path: ${BASE}/${cat.dir}/${service}/README.md

Content:
${content}

Use the Write tool. Make sure the directory exists first with: mkdir -p ${BASE}/${cat.dir}/${service}
Confirm the file was written.`,
      { label: `write-manual:${service}`, phase: 'Write Files' }
    )
  )
))

phase('Master Manual')

// Build master manual that links to all individual READMEs
const allServices = CATEGORIES.flatMap(c => c.services.map(s => ({ ...s, catDir: c.dir })))

await agent(
  `Write a file to /Volumes/storage/aws/SERVICES_MANUAL.md

This is a master index manual for all AWS services in this learning project.

Write EXACTLY this content (fill in the table rows for all 55 services listed):

# AWS Services Manual

A complete reference for all ${allServices.length} AWS services in this project, each with a standalone demo and detailed README.

## Quick Start

\`\`\`bash
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
\`\`\`

---

## Services by Category

${CATEGORIES.map(cat => `
### ${cat.dir.replace(/^\d+-/, '').toUpperCase().replace(/-/g,' ')}

| Service | Full Name | README | Demo |
|---------|-----------|--------|------|
${cat.services.map(s => `| \`${s.name}\` | ${s.full} | [README](services/${cat.dir}/${s.name}/README.md) | [demo.sh](services/${cat.dir}/${s.name}/demo.sh) |`).join('\n')}
`).join('\n')}

---

## Service Cheat Sheet

| Service | CLI Prefix | Create | List | Delete |
|---------|-----------|--------|------|--------|
| S3 | \`s3\` | \`mb s3://name\` | \`ls\` | \`rb s3://name\` |
| DynamoDB | \`dynamodb\` | \`create-table\` | \`list-tables\` | \`delete-table\` |
| SQS | \`sqs\` | \`create-queue\` | \`list-queues\` | \`delete-queue\` |
| SNS | \`sns\` | \`create-topic\` | \`list-topics\` | \`delete-topic\` |
| Lambda | \`lambda\` | \`create-function\` | \`list-functions\` | \`delete-function\` |
| Kinesis | \`kinesis\` | \`create-stream\` | \`list-streams\` | \`delete-stream\` |
| IAM | \`iam\` | \`create-user\` | \`list-users\` | \`delete-user\` |
| KMS | \`kms\` | \`create-key\` | \`list-keys\` | \`schedule-key-deletion\` |
| Secrets Manager | \`secretsmanager\` | \`create-secret\` | \`list-secrets\` | \`delete-secret\` |
| CloudWatch | \`cloudwatch\` | \`put-metric-data\` | \`list-metrics\` | \`delete-alarms\` |
| CloudWatch Logs | \`logs\` | \`create-log-group\` | \`describe-log-groups\` | \`delete-log-group\` |
| StepFunctions | \`stepfunctions\` | \`create-state-machine\` | \`list-state-machines\` | \`delete-state-machine\` |
| SSM | \`ssm\` | \`put-parameter\` | \`describe-parameters\` | \`delete-parameter\` |
| EC2 | \`ec2\` | \`run-instances\` | \`describe-instances\` | \`terminate-instances\` |
| ECR | \`ecr\` | \`create-repository\` | \`describe-repositories\` | \`delete-repository\` |
| ECS | \`ecs\` | \`create-cluster\` | \`list-clusters\` | \`delete-cluster\` |
| RDS | \`rds\` | \`create-db-instance\` | \`describe-db-instances\` | \`delete-db-instance\` |
| Route53 | \`route53\` | \`create-hosted-zone\` | \`list-hosted-zones\` | \`delete-hosted-zone\` |
| API Gateway | \`apigateway\` | \`create-rest-api\` | \`get-rest-apis\` | \`delete-rest-api\` |
| Cognito IDP | \`cognito-idp\` | \`create-user-pool\` | \`list-user-pools\` | \`delete-user-pool\` |
| EventBridge | \`events\` | \`create-event-bus\` | \`list-event-buses\` | \`delete-event-bus\` |
| Athena | \`athena\` | \`create-work-group\` | \`list-work-groups\` | \`delete-work-group\` |
| Glue | \`glue\` | \`create-database\` | \`get-databases\` | \`delete-database\` |
| SES | \`ses\` | \`verify-email-identity\` | \`list-identities\` | \`delete-identity\` |
| CodeCommit | \`codecommit\` | \`create-repository\` | \`list-repositories\` | \`delete-repository\` |
| STS | \`sts\` | — | \`get-caller-identity\` | — |

---

## Project Structure

\`\`\`
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
\`\`\`

Use the Write tool to create /Volumes/storage/aws/SERVICES_MANUAL.md with the above content.`,
  { label: 'write:master-manual', phase: 'Master Manual' }
)

return {
  totalServices: allServices.length,
  categories: CATEGORIES.length,
  files: allServices.map(s => `services/${s.catDir}/${s.name}/README.md`),
}

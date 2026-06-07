# AWS CloudFormation

## What is it?
AWS CloudFormation is an infrastructure-as-code (IaC) service that lets you model, provision, and manage AWS resources using declarative templates written in JSON or YAML. Instead of clicking through the console or running individual CLI commands, you describe your desired infrastructure in a template and CloudFormation handles creating, updating, and deleting resources in the correct order. It is the native AWS IaC solution and is ideal when you want repeatable, version-controlled infrastructure deployments. Its main benefit is that it treats your entire environment as a single unit — called a stack — making it easy to replicate environments and roll back changes.

## Key Concepts
- **Template** — A JSON or YAML document that declares the AWS resources to create. It is the blueprint for your infrastructure.
- **Stack** — A single unit of related AWS resources created and managed together from one template. Creating, updating, or deleting a stack operates on all its resources.
- **Stack Status** — A lifecycle state (e.g. `CREATE_COMPLETE`, `UPDATE_ROLLBACK_COMPLETE`) that tells you what CloudFormation is currently doing with a stack.
- **Resources** — The AWS services declared inside a template (e.g. `AWS::S3::Bucket`, `AWS::SQS::Queue`). These are the actual infrastructure objects CloudFormation manages.
- **Outputs** — Named values exported from a stack (e.g. a bucket name or queue URL) that other stacks or users can reference.
- **Change Set** — A preview of proposed changes to an existing stack before they are applied, helping you avoid unintended deletions or replacements.

## When to Use
- **Repeatable environment provisioning** — Spin up identical dev, staging, and production environments from the same template, eliminating configuration drift.
- **Multi-resource deployments** — Deploy an application that requires an S3 bucket, SQS queue, IAM role, and Lambda function all at once, with proper dependency ordering.
- **Disaster recovery** — Re-create an entire environment in a new region by running the same template, reducing recovery time from hours to minutes.
- **Team infrastructure collaboration** — Store templates in Git so that infrastructure changes go through code review, just like application code.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create a stack | `awslocal cloudformation create-stack --stack-name my-stack --template-body file://template.json` |
| List all stacks | `awslocal cloudformation list-stacks --stack-status-filter CREATE_COMPLETE` |
| Describe a stack | `awslocal cloudformation describe-stacks --stack-name my-stack` |
| List stack resources | `awslocal cloudformation list-stack-resources --stack-name my-stack` |
| Update a stack | `awslocal cloudformation update-stack --stack-name my-stack --template-body file://template.json` |
| Create a change set | `awslocal cloudformation create-change-set --stack-name my-stack --change-set-name my-change --template-body file://template.json` |
| Delete a stack | `awslocal cloudformation delete-stack --stack-name my-stack` |
| Wait for create | `awslocal cloudformation wait stack-create-complete --stack-name my-stack` |

## Example Walkthrough

1. **Create the stack** — Provision an S3 bucket and SQS queue from an inline template.
   ```bash
   awslocal cloudformation create-stack \
     --stack-name demo-cfn-stack \
     --template-body '{"AWSTemplateFormatVersion":"2010-09-09","Resources":{"DemoBucket":{"Type":"AWS::S3::Bucket","Properties":{"BucketName":"cfn-demo-bucket-01"}},"DemoQueue":{"Type":"AWS::SQS::Queue","Properties":{"QueueName":"cfn-demo-queue"}}},"Outputs":{"BucketName":{"Value":{"Ref":"DemoBucket"}},"QueueUrl":{"Value":{"Ref":"DemoQueue"}}}}'
   ```

2. **Wait for creation to finish** — Block until the stack reaches `CREATE_COMPLETE`.
   ```bash
   awslocal cloudformation wait stack-create-complete \
     --stack-name demo-cfn-stack
   ```

3. **Describe stack status** — Confirm the stack and its current status.
   ```bash
   awslocal cloudformation describe-stacks \
     --stack-name demo-cfn-stack \
     --query 'Stacks[*].{Name:StackName,Status:StackStatus}' \
     --output table
   ```

4. **List stack resources** — View every resource CloudFormation created and its physical ID.
   ```bash
   awslocal cloudformation list-stack-resources \
     --stack-name demo-cfn-stack \
     --query 'StackResourceSummaries[*].{Type:ResourceType,ID:PhysicalResourceId,Status:ResourceStatus}' \
     --output table
   ```

5. **Fetch stack outputs** — Retrieve the exported bucket name and queue URL.
   ```bash
   awslocal cloudformation describe-stacks \
     --stack-name demo-cfn-stack \
     --query 'Stacks[*].Outputs[*].{Key:OutputKey,Value:OutputValue}' \
     --output table
   ```

6. **Delete the stack** — Remove all resources that were created by this stack.
   ```bash
   awslocal cloudformation delete-stack \
     --stack-name demo-cfn-stack
   ```

## Important Flags & Options

| Flag / Option | Description |
|---------------|-------------|
| `--stack-name` | The name that uniquely identifies the stack. |
| `--template-body` | Inline template JSON/YAML string or `file://path/to/template.json`. |
| `--template-url` | S3 URL pointing to the template file (alternative to `--template-body`). |
| `--parameters` | Key-value pairs that override parameter defaults in the template. |
| `--capabilities CAPABILITY_IAM` | Required when a template creates IAM resources. |
| `--stack-status-filter` | Filters the `list-stacks` output to specific statuses (e.g. `CREATE_COMPLETE`). |
| `--query` | JMESPath expression to filter and shape the JSON response. |
| `--output table` | Formats the response as a readable ASCII table. |

## How to Run the Demo
```bash
cd services/08-management/cloudformation
bash demo.sh
```

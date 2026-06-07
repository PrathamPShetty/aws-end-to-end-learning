# Amazon S3 Control

## What is it?
Amazon S3 Control provides account-level and organization-level management capabilities for Amazon S3 that go beyond what individual bucket settings can offer. It is the service behind features like S3 Access Points, S3 Batch Operations, and account-wide Public Access Block settings. Use S3 Control when you need to enforce uniform security policies across every bucket in your account, create scoped access entry points for specific applications, or run bulk operations against millions of objects at once. Its main benefit is centralized governance — one place to define rules and access patterns that apply account-wide rather than bucket-by-bucket.

## Key Concepts
- **Account-level Public Access Block** — A single on/off switch that blocks all public access to every bucket in the account, overriding any individual bucket or object ACL settings.
- **Access Point** — A named network endpoint attached to a specific S3 bucket. Each application or team gets its own access point with its own policy, keeping permissions isolated and auditable.
- **S3 Batch Operations** — A managed job that performs a single operation (e.g. copy, tag, restore, invoke Lambda) across billions of objects listed in a manifest CSV.
- **Job** — The unit of work in S3 Batch Operations. A job reads a manifest, applies an operation to each object, and writes a completion report.
- **Manifest** — A CSV or S3 Inventory file that lists every object the batch job should act on.
- **Storage Lens** — An account-level analytics dashboard that surfaces storage metrics and usage trends across all buckets.

## When to Use
- **Enterprise security hardening** — Block all public S3 access across an entire AWS account with a single API call to prevent accidental data exposure.
- **Multi-tenant application isolation** — Give each microservice or team its own Access Point with a least-privilege policy so they can only touch their own data in a shared bucket.
- **Bulk object operations** — Use Batch Operations to re-tag millions of archived objects, copy an entire data lake partition to another region, or restore a large set of Glacier objects.
- **Organization-wide governance** — Apply Public Access Block and Storage Lens configurations across all accounts in an AWS Organization from a central management account.

## CLI Quick Reference (awslocal)

### Public Access Block (account-level)
| Operation | Command |
|---|---|
| Block all public access | `awslocal s3control put-public-access-block --account-id 000000000000 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true` |
| Get current settings | `awslocal s3control get-public-access-block --account-id 000000000000` |
| Remove the block | `awslocal s3control delete-public-access-block --account-id 000000000000` |

### Access Points
| Operation | Command |
|---|---|
| Create access point | `awslocal s3control create-access-point --account-id 000000000000 --name my-access-point --bucket my-bucket` |
| List access points | `awslocal s3control list-access-points --account-id 000000000000 --bucket my-bucket` |
| Describe access point | `awslocal s3control get-access-point --account-id 000000000000 --name my-access-point` |
| Delete access point | `awslocal s3control delete-access-point --account-id 000000000000 --name my-access-point` |

### Batch Operations
| Operation | Command |
|---|---|
| Create a batch job | `awslocal s3control create-job --account-id 000000000000 --operation '{"S3PutObjectTagging":{"TagSet":[{"Key":"env","Value":"prod"}]}}' --manifest '...' --report '...' --role-arn arn:aws:iam::000000000000:role/batch-role --priority 10 --no-confirmation-required` |
| List batch jobs | `awslocal s3control list-jobs --account-id 000000000000` |
| Describe a job | `awslocal s3control describe-job --account-id 000000000000 --job-id <job-id>` |

## Example Walkthrough

1. **Create a bucket** — Create a regular S3 bucket that S3 Control will manage.
   ```bash
   awslocal s3api create-bucket --bucket my-app-data
   ```

2. **Block all public access at the account level** — Prevent any bucket or object in the account from being made public.
   ```bash
   awslocal s3control put-public-access-block \
     --account-id 000000000000 \
     --public-access-block-configuration \
       BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
   ```

3. **Verify the account-level settings** — Confirm the block configuration is active.
   ```bash
   awslocal s3control get-public-access-block \
     --account-id 000000000000 \
     --query 'PublicAccessBlockConfiguration' \
     --output table
   ```

4. **Create an Access Point** — Give a specific application a scoped entry point into the bucket.
   ```bash
   awslocal s3control create-access-point \
     --account-id 000000000000 \
     --name orders-service-ap \
     --bucket my-app-data
   ```

5. **List Access Points for the bucket** — See all access points and their network origins.
   ```bash
   awslocal s3control list-access-points \
     --account-id 000000000000 \
     --bucket my-app-data \
     --query 'AccessPointList[].{Name:Name,Bucket:Bucket,NetworkOrigin:NetworkOrigin}' \
     --output table
   ```

6. **Describe the Access Point** — Inspect the full details of a single access point.
   ```bash
   awslocal s3control get-access-point \
     --account-id 000000000000 \
     --name orders-service-ap
   ```

7. **Clean up** — Delete the access point and bucket when done.
   ```bash
   awslocal s3control delete-access-point \
     --account-id 000000000000 \
     --name orders-service-ap

   awslocal s3 rb s3://my-app-data --force
   ```

## Important Flags & Options

| Flag / Option | Used With | Description |
|---|---|---|
| `--account-id` | All commands | 12-digit AWS account ID. Use `000000000000` with LocalStack. |
| `--public-access-block-configuration` | `put-public-access-block` | Comma-separated key=value pairs for all four block settings. |
| `--name` | `create-access-point`, `get-access-point`, `delete-access-point` | Unique name for the access point (3–50 lowercase characters). |
| `--bucket` | `create-access-point`, `list-access-points` | The S3 bucket the access point is attached to. |
| `--operation` | `create-job` | JSON object describing the S3 Batch Operations action to run. |
| `--manifest` | `create-job` | JSON specifying the manifest file location and format. |
| `--report` | `create-job` | JSON specifying where to write the job completion report. |
| `--priority` | `create-job` | Integer priority (higher = processed first) when multiple jobs are queued. |
| `--no-confirmation-required` | `create-job` | Start the job immediately without a manual confirmation step. |
| `--query` | Any command | JMESPath expression to filter/reshape the JSON response. |

## How to Run the Demo

```bash
cd services/02-storage/s3control
bash demo.sh
```

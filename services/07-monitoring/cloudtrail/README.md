# AWS CloudTrail

## What is it?
AWS CloudTrail is an auditing and governance service that records every API call made in your AWS account — who made it, when, from where, and what changed. You use it when you need a complete, tamper-evident history of account activity for security investigations, compliance audits, or troubleshooting unexpected resource changes. Its main benefit is providing accountability: if a resource is deleted or a policy is changed, CloudTrail gives you a full audit trail that identifies the exact identity, time, and source IP of the action.

## Key Concepts
- **Trail** — A configuration that tells CloudTrail which events to record and where to deliver the log files (an S3 bucket and optionally CloudWatch Logs).
- **Event** — A record of a single API call or AWS console action, containing the event name, time, source IP, user identity, and the request/response parameters.
- **Management Event** — Control-plane operations that create, modify, or delete AWS resources (e.g., `CreateBucket`, `RunInstances`, `DeleteUser`). Recorded by default.
- **Data Event** — High-volume, data-plane operations on resources (e.g., S3 `GetObject`, Lambda `Invoke`). Must be explicitly enabled because of volume.
- **Log File Validation** — An optional feature that uses SHA-256 hashing and digital signatures so you can prove a log file has not been altered after delivery.
- **Event History** — A 90-day rolling window of management events viewable in the console or via `lookup-events` — available without creating a trail.

## When to Use
- Meet compliance requirements (PCI-DSS, SOC 2, HIPAA) that mandate a complete audit log of all API activity.
- Investigate security incidents by looking up who created, modified, or deleted a specific resource.
- Detect unexpected or unauthorised IAM changes (new users, policy attachments, access key creation).
- Forward CloudTrail events into CloudWatch Logs to trigger real-time alarms on sensitive API calls.

## CLI Quick Reference (awslocal)

### Create an S3 bucket for trail logs
```bash
awslocal s3 mb s3://my-cloudtrail-logs
```

### Create a trail
```bash
awslocal cloudtrail create-trail \
  --name "my-trail" \
  --s3-bucket-name "my-cloudtrail-logs"
```

### Start logging
```bash
awslocal cloudtrail start-logging --name "my-trail"
```

### Describe trails
```bash
awslocal cloudtrail describe-trails --trail-name-list "my-trail"
```

### Get trail logging status
```bash
awslocal cloudtrail get-trail-status --name "my-trail"
```

### Look up recent events
```bash
awslocal cloudtrail lookup-events --max-results 10
```

### Look up events by attribute
```bash
awslocal cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket
```

### Stop logging
```bash
awslocal cloudtrail stop-logging --name "my-trail"
```

### Update a trail (e.g., enable log file validation)
```bash
awslocal cloudtrail update-trail \
  --name "my-trail" \
  --enable-log-file-validation
```

### Delete a trail
```bash
awslocal cloudtrail delete-trail --name "my-trail"
```

## Example Walkthrough

1. **Create an S3 bucket to store CloudTrail log files**
   ```bash
   awslocal s3 mb s3://demo-cloudtrail-bucket
   ```
   Provides the delivery destination; CloudTrail writes gzip-compressed JSON log files here under `AWSLogs/<account-id>/`.

2. **Attach a bucket policy allowing CloudTrail to write to it**
   ```bash
   ACCOUNT_ID=$(awslocal sts get-caller-identity --query Account --output text)
   awslocal s3api put-bucket-policy \
     --bucket "demo-cloudtrail-bucket" \
     --policy "{
       \"Version\":\"2012-10-17\",
       \"Statement\":[{
         \"Effect\":\"Allow\",
         \"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},
         \"Action\":\"s3:PutObject\",
         \"Resource\":\"arn:aws:s3:::demo-cloudtrail-bucket/AWSLogs/*\"
       }]
     }"
   ```
   Without this policy CloudTrail will fail to deliver logs; the `Principal` must be the CloudTrail service.

3. **Create the trail pointing at the bucket**
   ```bash
   awslocal cloudtrail create-trail \
     --name "demo-trail" \
     --s3-bucket-name "demo-cloudtrail-bucket"
   ```
   Registers the trail configuration; the trail is created in a stopped state and does not yet record events.

4. **Start logging so events are captured**
   ```bash
   awslocal cloudtrail start-logging --name "demo-trail"
   ```
   Activates event recording; from this point all management API calls will be written to the S3 bucket.

5. **Confirm the trail is active**
   ```bash
   awslocal cloudtrail get-trail-status \
     --name "demo-trail" \
     --query '{IsLogging:IsLogging,LatestDeliveryTime:LatestDeliveryTime}' \
     --output table
   ```
   `IsLogging: true` confirms the trail is running and the latest delivery timestamp shows when the last file was written.

6. **Search recent events in the 90-day event history**
   ```bash
   awslocal cloudtrail lookup-events \
     --max-results 5 \
     --query 'Events[*].{EventName:EventName,EventTime:EventTime,Username:Username}' \
     --output table
   ```
   Queries the built-in event history without needing to parse S3 log files — useful for quick ad-hoc lookups.

## Important Flags & Options

| Flag / Option | Command | Description |
|---|---|---|
| `--name` | `create-trail`, `start-logging`, `stop-logging`, `get-trail-status`, `delete-trail` | The trail name or ARN to act on |
| `--s3-bucket-name` | `create-trail`, `update-trail` | S3 bucket where CloudTrail delivers log files |
| `--s3-key-prefix` | `create-trail`, `update-trail` | Optional prefix inside the bucket (e.g., `cloudtrail/`) |
| `--include-global-service-events` | `create-trail`, `update-trail` | Also record IAM, STS, and CloudFront events (global services) |
| `--is-multi-region-trail` | `create-trail`, `update-trail` | Record events from all regions, not just the current one |
| `--enable-log-file-validation` | `create-trail`, `update-trail` | Generate digest files so you can verify logs have not been tampered with |
| `--cloud-watch-logs-log-group-arn` | `create-trail`, `update-trail` | ARN of a CloudWatch Logs group to also stream events to for real-time alerting |
| `--lookup-attributes` | `lookup-events` | Filter by `AttributeKey` (e.g., `EventName`, `Username`, `ResourceName`) and `AttributeValue` |
| `--max-results` | `lookup-events` | Maximum number of events returned per page (1–50) |
| `--start-time` / `--end-time` | `lookup-events` | ISO 8601 timestamps to narrow the search window |
| `--trail-name-list` | `describe-trails` | Comma-separated list of trail names to describe; omit to list all |

## How to Run the Demo
```bash
cd services/07-monitoring/cloudtrail
bash demo.sh
```

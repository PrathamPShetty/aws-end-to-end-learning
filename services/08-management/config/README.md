# AWS Config

## What is it?
AWS Config is a continuous auditing and compliance service that records the configuration state of your AWS resources over time and evaluates those configurations against rules you define. Whenever a resource is created, modified, or deleted, Config captures a configuration snapshot and stores it in S3, giving you a complete history of every change. You can then write or use AWS-managed rules to check whether resources comply with your security and operational policies — for example, whether S3 buckets block public access or whether EC2 instances use approved AMIs. Its main benefit is that it provides full visibility into the "who changed what and when" of your infrastructure and automates compliance reporting without manual audits.

## Key Concepts
- **Configuration Recorder** — The component that continuously monitors supported AWS resources in your account and records their configuration changes. Only one recorder exists per region.
- **Delivery Channel** — Defines where Config sends configuration snapshots and compliance results — typically an S3 bucket and optionally an SNS topic for real-time notifications.
- **Config Rule** — A policy that evaluates whether your resources comply with a desired configuration. Rules can be AWS-managed (built-in) or custom (backed by a Lambda function).
- **Configuration Item** — A point-in-time snapshot of a single resource's configuration, including metadata, attributes, relationships, and the time of capture.
- **Compliance Status** — The result of evaluating a resource against a Config rule: `COMPLIANT`, `NON_COMPLIANT`, `NOT_APPLICABLE`, or `INSUFFICIENT_DATA`.
- **Configuration Snapshot** — A complete dump of all current resource configurations in a region, delivered to S3 on demand or on a schedule.

## When to Use
- **Security compliance auditing** — Automatically detect S3 buckets that allow public read access, security groups that open port 22 to the world, or IAM users without MFA enabled.
- **Change management and forensics** — Investigate an outage or security incident by reviewing the exact configuration state of every relevant resource before and after the event.
- **Regulatory compliance** — Continuously prove to auditors (SOC 2, PCI-DSS, HIPAA) that your infrastructure meets required controls, with Config generating evidence automatically.
- **Drift detection** — Identify resources that have deviated from your approved baseline configuration and trigger automated remediation via SSM Automation or Lambda.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create/update configuration recorder | `awslocal configservice put-configuration-recorder --configuration-recorder "name=default,roleARN=arn:aws:iam::000000000000:role/config-role,recordingGroup={allSupported=true}"` |
| Create/update delivery channel | `awslocal configservice put-delivery-channel --delivery-channel "name=default,s3BucketName=my-config-bucket"` |
| Start the recorder | `awslocal configservice start-configuration-recorder --configuration-recorder-name default` |
| Stop the recorder | `awslocal configservice stop-configuration-recorder --configuration-recorder-name default` |
| Describe recorder status | `awslocal configservice describe-configuration-recorder-status` |
| Create/update a Config rule | `awslocal configservice put-config-rule --config-rule 'ConfigRuleName=s3-public-read-prohibited,Source={Owner=AWS,SourceIdentifier=S3_BUCKET_PUBLIC_READ_PROHIBITED}'` |
| List Config rules | `awslocal configservice describe-config-rules` |
| Get compliance by resource type | `awslocal configservice get-compliance-summary-by-resource-type` |
| Delete a Config rule | `awslocal configservice delete-config-rule --config-rule-name s3-public-read-prohibited` |

## Example Walkthrough

1. **Create an S3 delivery bucket** — Config needs a bucket to store configuration snapshots and history.
   ```bash
   awslocal s3 mb s3://config-demo-delivery-bucket
   ```

2. **Put the configuration recorder** — Tell Config to record all supported resources in this region.
   ```bash
   awslocal configservice put-configuration-recorder \
     --configuration-recorder \
       "name=default,roleARN=arn:aws:iam::000000000000:role/config-role,recordingGroup={allSupported=true,includeGlobalResourceTypes=false}"
   ```

3. **Put the delivery channel** — Direct Config to deliver snapshots to the S3 bucket every six hours.
   ```bash
   awslocal configservice put-delivery-channel \
     --delivery-channel \
       "name=default,s3BucketName=config-demo-delivery-bucket,configSnapshotDeliveryProperties={deliveryFrequency=Six_Hours}"
   ```

4. **Start the configuration recorder** — Begin actively recording resource configuration changes.
   ```bash
   awslocal configservice start-configuration-recorder \
     --configuration-recorder-name default
   ```

5. **Verify recorder is running** — Confirm the recorder status shows `recording: true`.
   ```bash
   awslocal configservice describe-configuration-recorder-status \
     --configuration-recorder-names default \
     --query 'ConfigurationRecordersStatus[*].{Name:name,Recording:recording}' \
     --output table
   ```

6. **Add a managed compliance rule** — Enforce that no S3 bucket allows public read access.
   ```bash
   awslocal configservice put-config-rule \
     --config-rule \
       'ConfigRuleName=s3-public-read-prohibited,Source={Owner=AWS,SourceIdentifier=S3_BUCKET_PUBLIC_READ_PROHIBITED}'
   ```

7. **View all Config rules and their state** — List every rule and confirm it is active.
   ```bash
   awslocal configservice describe-config-rules \
     --query 'ConfigRules[*].{Name:ConfigRuleName,State:ConfigRuleState,Owner:Source.Owner}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description |
|---------------|-------------|
| `--configuration-recorder` | Inline definition of the recorder including its name, IAM role ARN, and which resource types to record. |
| `--delivery-channel` | Inline definition of where to send snapshots: S3 bucket name, optional SNS topic ARN, and snapshot frequency. |
| `--configuration-recorder-name` | Name of the recorder to start, stop, or describe (usually `default`). |
| `--config-rule` | Inline JSON/shorthand definition of a rule including its name, source owner (`AWS` or `CUSTOM_LAMBDA`), and source identifier. |
| `allSupported=true` | Records all supported resource types. Set to `false` and provide `resourceTypes` to record only specific types. |
| `includeGlobalResourceTypes` | When `true`, records IAM users, groups, roles, and policies (global resources). Requires `allSupported=true`. |
| `deliveryFrequency` | How often Config delivers configuration snapshots to S3. Valid values: `One_Hour`, `Three_Hours`, `Six_Hours`, `Twelve_Hours`, `TwentyFour_Hours`. |
| `SourceIdentifier` | The identifier of an AWS-managed rule, e.g. `S3_BUCKET_PUBLIC_READ_PROHIBITED` or `ROOT_MFA_ENABLED`. |

## How to Run the Demo
```bash
cd services/08-management/config
bash demo.sh
```

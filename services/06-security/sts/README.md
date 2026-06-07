# AWS STS (Security Token Service)

## What is it?
AWS STS (Security Token Service) is the service that issues temporary, limited-privilege AWS credentials — an access key ID, a secret access key, and a session token — that expire automatically after a configurable duration. Every time an IAM role is assumed (by a Lambda function, an EC2 instance, a CI/CD pipeline, or a federated user), STS is what issues those short-lived credentials. Because the credentials expire, they are far safer than permanent IAM user access keys, which are a common source of credential leaks. STS is the backbone of the AWS assume-role pattern, cross-account access, and all federation scenarios.

## Key Concepts
- **Temporary Security Credentials** — A trio of values (AccessKeyId, SecretAccessKey, SessionToken) that grant AWS access for a limited time (15 minutes to 12 hours).
- **AssumeRole** — The most-used STS API; exchanges your current identity for a different IAM role's permissions, possibly in another AWS account.
- **Session Policy** — An optional IAM policy passed inline when assuming a role to further restrict the permissions of that specific session (cannot exceed the role's permissions).
- **External ID** — A secret value required when assuming a role from a third-party account; prevents the confused deputy problem.
- **Caller Identity** — The principal (user, role, or account) making the current API call; retrieved with `get-caller-identity`.
- **GetSessionToken** — Produces temporary credentials for an existing IAM user, often used to satisfy MFA requirements for sensitive operations.

## When to Use
- Granting a CI/CD pipeline (GitHub Actions, Jenkins) access to deploy to AWS without storing permanent IAM access keys in the pipeline config.
- Cross-account access: assuming a role in the production account from the tooling account to run a deployment.
- Least-privilege sessions: assuming a role with a session policy that restricts access to only one specific S3 bucket for that single operation.
- MFA enforcement: requiring `get-session-token` with an MFA token before allowing destructive operations like deleting RDS snapshots.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Get caller identity | `awslocal sts get-caller-identity` |
| Assume a role | `awslocal sts assume-role --role-arn arn:aws:iam::000000000000:role/MyRole --role-session-name my-session` |
| Assume role with duration | `awslocal sts assume-role --role-arn <arn> --role-session-name ci-deploy --duration-seconds 3600` |
| Assume role with inline policy | `awslocal sts assume-role --role-arn <arn> --role-session-name restricted --policy file://session-policy.json` |
| Get session token | `awslocal sts get-session-token --duration-seconds 900` |
| Get session token with MFA | `awslocal sts get-session-token --serial-number arn:aws:iam::000000000000:mfa/mydevice --token-code 123456` |
| Decode authorization message | `awslocal sts decode-authorization-message --encoded-message <encoded>` |

## Example Walkthrough

1. **Check who you are right now**
   ```bash
   awslocal sts get-caller-identity
   ```
   Returns your current AccountId, UserId, and ARN — the first command to run when debugging an "access denied" error.

2. **Create an IAM role that any principal in the account can assume**
   ```bash
   awslocal iam create-role \
     --role-name DeployRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {"AWS": "arn:aws:iam::000000000000:root"},
         "Action": "sts:AssumeRole"
       }]
     }'
   ```
   The trust policy is what permits STS to let someone assume this role. Without it, `assume-role` is denied.

3. **Assume the role and capture the temporary credentials**
   ```bash
   CREDS=$(awslocal sts assume-role \
     --role-arn arn:aws:iam::000000000000:role/DeployRole \
     --role-session-name pipeline-run-42 \
     --duration-seconds 3600)

   export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
   export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
   export AWS_SESSION_TOKEN=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SessionToken'])")
   ```
   Your shell is now operating as `DeployRole`. Any subsequent `awslocal` commands use these short-lived credentials.

4. **Verify you are now acting as the assumed role**
   ```bash
   awslocal sts get-caller-identity
   ```
   The ARN in the response will now show `assumed-role/DeployRole/pipeline-run-42` — confirming the role switch succeeded.

5. **Assume the role with a restrictive inline session policy**
   ```bash
   awslocal sts assume-role \
     --role-arn arn:aws:iam::000000000000:role/DeployRole \
     --role-session-name scoped-upload \
     --duration-seconds 900 \
     --policy '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": ["s3:PutObject"],
         "Resource": "arn:aws:s3:::my-deploy-bucket/releases/*"
       }]
     }' \
     --query 'Credentials.{Key:AccessKeyId,Expiry:Expiration}'
   ```
   Even though `DeployRole` may have broader permissions, this session is limited to uploading to one specific S3 prefix.

6. **Get a session token (extend existing user credentials)**
   ```bash
   awslocal sts get-session-token \
     --duration-seconds 900 \
     --query 'Credentials.{AccessKeyId:AccessKeyId,Expiration:Expiration}'
   ```
   Useful for wrapping your IAM user credentials in a short-lived session, or for satisfying MFA requirements on sensitive API calls.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--role-arn` | Full ARN of the IAM role to assume |
| `--role-session-name` | Identifier for the session; appears in CloudTrail logs (required) |
| `--duration-seconds` | Session lifetime: 900–43200 for `assume-role`, 900–129600 for `get-session-token` |
| `--policy` | Inline JSON session policy to further restrict the assumed session's permissions |
| `--policy-arns` | ARNs of managed policies to use as additional session policies |
| `--external-id` | Required secret when assuming a cross-account role to prevent confused deputy attacks |
| `--serial-number` | ARN of MFA device when MFA is required to assume the role |
| `--token-code` | Current 6-digit MFA code from the device specified by `--serial-number` |
| `--encoded-message` | Base64-encoded authorization failure message to decode with `decode-authorization-message` |

## How to Run the Demo
```bash
cd services/06-security/sts
bash demo.sh
```

# AWS Secrets Manager

## What is it?
AWS Secrets Manager is a fully managed service for storing, retrieving, and automatically rotating sensitive configuration values such as database passwords, API keys, and OAuth tokens. Instead of hard-coding secrets in application code or environment variables, your application calls Secrets Manager at runtime to fetch the current value. The service integrates with Amazon RDS, Redshift, and DocumentDB to rotate database credentials automatically without any downtime. The main benefit is eliminating plaintext secrets from code repositories and centralising access control through IAM policies.

## Key Concepts
- **Secret** — The primary resource: a named container that holds a secret value (string or binary) plus metadata and version history.
- **Secret Value** — The actual sensitive data stored inside a secret; typically a JSON string (e.g., `{"username":"admin","password":"s3cr3t"}`).
- **Version** — Each time a secret value is updated, a new version is created and labelled with a staging label (`AWSCURRENT`, `AWSPREVIOUS`).
- **Rotation** — An automated process where Secrets Manager calls a Lambda function on a schedule to replace the secret value with a newly generated one.
- **Staging Label** — Tags applied to secret versions (`AWSCURRENT`, `AWSPENDING`, `AWSPREVIOUS`) to identify which version is active.
- **Resource Policy** — An optional JSON policy attached to a secret to allow cross-account access.

## When to Use
- Storing database credentials (RDS username/password) that your application fetches at startup instead of reading from an `.env` file.
- Rotating API keys for third-party services on a weekly schedule without redeploying your application.
- Granting a Lambda function access to a secret via IAM so only that function can read it, with all access logged in CloudTrail.
- Sharing secrets securely across AWS accounts without emailing credentials.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create secret (string) | `awslocal secretsmanager create-secret --name prod/db-password --secret-string "p@ssw0rd"` |
| Create secret (JSON) | `awslocal secretsmanager create-secret --name prod/db-creds --secret-string '{"username":"admin","password":"p@ss"}'` |
| Get secret value | `awslocal secretsmanager get-secret-value --secret-id prod/db-creds` |
| Update secret value | `awslocal secretsmanager put-secret-value --secret-id prod/db-creds --secret-string '{"username":"admin","password":"new"}'` |
| Describe secret | `awslocal secretsmanager describe-secret --secret-id prod/db-creds` |
| List secrets | `awslocal secretsmanager list-secrets` |
| List versions | `awslocal secretsmanager list-secret-version-ids --secret-id prod/db-creds` |
| Tag secret | `awslocal secretsmanager tag-resource --secret-id prod/db-creds --tags Key=env,Value=prod` |
| Delete secret | `awslocal secretsmanager delete-secret --secret-id prod/db-creds --force-delete-without-recovery` |

## Example Walkthrough

1. **Create a secret holding JSON database credentials**
   ```bash
   SECRET_ARN=$(awslocal secretsmanager create-secret \
     --name prod/db-credentials \
     --description "Production RDS credentials" \
     --secret-string '{"username":"admin","password":"initialP@ss123"}' \
     --query 'ARN' --output text)
   echo "Secret ARN: $SECRET_ARN"
   ```
   Creates a new secret named `prod/db-credentials` with version 1 labelled `AWSCURRENT`.

2. **Retrieve the current secret value**
   ```bash
   awslocal secretsmanager get-secret-value \
     --secret-id prod/db-credentials \
     --query 'SecretString' \
     --output text
   ```
   Returns the JSON string so your application can parse the username and password.

3. **Rotate the password by putting a new version**
   ```bash
   awslocal secretsmanager put-secret-value \
     --secret-id prod/db-credentials \
     --secret-string '{"username":"admin","password":"rotatedP@ss456"}'
   ```
   Creates a new version tagged `AWSCURRENT`; the old version is automatically re-labelled `AWSPREVIOUS`.

4. **List all versions to see the rotation history**
   ```bash
   awslocal secretsmanager list-secret-version-ids \
     --secret-id prod/db-credentials \
     --query 'Versions[*].{ID:VersionId,Stages:VersionStages}'
   ```
   Shows each version ID alongside its staging labels — useful to confirm rotation worked.

5. **Tag the secret for cost allocation and access control**
   ```bash
   awslocal secretsmanager tag-resource \
     --secret-id prod/db-credentials \
     --tags Key=env,Value=prod Key=team,Value=backend Key=project,Value=orders-api
   ```
   Tags help you find secrets in large accounts and write tag-based IAM policies.

6. **Delete the secret immediately (bypass the 7-day recovery window)**
   ```bash
   awslocal secretsmanager delete-secret \
     --secret-id prod/db-credentials \
     --force-delete-without-recovery
   ```
   Permanently removes the secret. In production, omit `--force-delete-without-recovery` to keep a 7-day safety window.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--name` | Unique name for the new secret |
| `--secret-id` | Name or ARN of an existing secret to retrieve or modify |
| `--secret-string` | Plaintext or JSON string value to store |
| `--secret-binary` | Binary secret value (base64-encoded) |
| `--description` | Human-readable description stored with the secret |
| `--version-stage` | Staging label to retrieve (default: `AWSCURRENT`) |
| `--tags` | Space-separated `Key=k,Value=v` pairs to attach |
| `--force-delete-without-recovery` | Skip the 7-day recovery window when deleting |
| `--recovery-window-in-days` | Days to wait before permanent deletion (7–30) |
| `--kms-key-id` | KMS key used to encrypt the secret (default: AWS-managed key) |

## How to Run the Demo
```bash
cd services/06-security/secretsmanager
bash demo.sh
```

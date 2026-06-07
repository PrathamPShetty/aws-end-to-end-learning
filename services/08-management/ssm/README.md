# AWS Systems Manager (SSM)

## What is it?
AWS Systems Manager (SSM) is an operations management service that provides a unified interface for viewing and controlling your AWS infrastructure. One of its most widely used features is the **Parameter Store**, a secure, hierarchical key-value store for managing application configuration and secrets such as database hostnames, passwords, and feature flags. Parameter Store supports plaintext (`String`) and encrypted (`SecureString`) values, versioning of every change, and fine-grained IAM access control. Its main benefit is that it removes hard-coded configuration from your application code and centralises secrets management without requiring a separate third-party tool.

## Key Concepts
- **Parameter** — A named configuration value stored in Parameter Store. Every parameter has a name, a value, a type, and a version number.
- **Parameter Name (Path)** — A slash-separated string such as `/prod/app/db_host`. The hierarchy lets you group related parameters and fetch an entire subtree with a single API call.
- **Type** — One of `String`, `StringList`, or `SecureString`. `SecureString` values are encrypted at rest using AWS KMS.
- **Version** — Every time a parameter is updated its version counter increments, and the full history is retained so you can audit or roll back.
- **SecureString** — A parameter type that stores the value encrypted via KMS. Retrieval requires the `--with-decryption` flag.
- **Path-based retrieval** — Using `get-parameters-by-path`, you can fetch all parameters under a given prefix in one call, which is ideal for bootstrapping an application's full config set.

## When to Use
- **Application configuration management** — Store database hostnames, port numbers, and feature flags in Parameter Store and have your application read them at startup instead of from environment variables or config files.
- **Secrets management (lightweight)** — Store API keys and passwords as `SecureString` parameters and control access via IAM, avoiding the need to hard-code credentials in source code or container images.
- **CI/CD pipeline variables** — Reference Parameter Store values in build pipelines so that environment-specific configuration is fetched dynamically at deploy time.
- **Auditing configuration changes** — Track every parameter change with built-in versioning and history, providing a full audit trail of who changed what and when.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create / overwrite a parameter | `awslocal ssm put-parameter --name /app/db_host --value "db.example.com" --type String --overwrite` |
| Get a single parameter | `awslocal ssm get-parameter --name /app/db_host` |
| Get an encrypted parameter | `awslocal ssm get-parameter --name /app/db_password --with-decryption` |
| Get all params under a path | `awslocal ssm get-parameters-by-path --path /app --with-decryption` |
| List parameters (describe) | `awslocal ssm describe-parameters` |
| View parameter history | `awslocal ssm get-parameter-history --name /app/db_host` |
| Delete a parameter | `awslocal ssm delete-parameter --name /app/db_host` |

## Example Walkthrough

1. **Store a plaintext parameter** — Write a database hostname to Parameter Store.
   ```bash
   awslocal ssm put-parameter \
     --name "/demo/app/db_host" \
     --value "db.internal.example.com" \
     --type String \
     --overwrite
   ```

2. **Store an encrypted secret** — Write a database password as a `SecureString`.
   ```bash
   awslocal ssm put-parameter \
     --name "/demo/app/db_password" \
     --value "s3cr3t-p@ssw0rd" \
     --type SecureString \
     --overwrite
   ```

3. **Read a single parameter with decryption** — Fetch and decrypt the password value.
   ```bash
   awslocal ssm get-parameter \
     --name "/demo/app/db_password" \
     --with-decryption \
     --query 'Parameter.{Name:Name,Value:Value,Type:Type}' \
     --output table
   ```

4. **Read all parameters under a path** — Fetch the entire `/demo/app` subtree at once.
   ```bash
   awslocal ssm get-parameters-by-path \
     --path "/demo/app" \
     --with-decryption \
     --query 'Parameters[*].{Name:Name,Value:Value,Type:Type}' \
     --output table
   ```

5. **Update a parameter** — Change the hostname to a replica and observe the new version.
   ```bash
   awslocal ssm put-parameter \
     --name "/demo/app/db_host" \
     --value "db-replica.internal.example.com" \
     --type String \
     --overwrite
   ```

6. **View parameter history** — Confirm both versions are recorded.
   ```bash
   awslocal ssm get-parameter-history \
     --name "/demo/app/db_host" \
     --query 'Parameters[*].{Version:Version,Value:Value}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description |
|---------------|-------------|
| `--name` | The full parameter name, including the path prefix (e.g. `/prod/app/db_host`). |
| `--value` | The value to store. For `SecureString`, this is the plaintext that will be encrypted. |
| `--type` | `String`, `StringList`, or `SecureString`. |
| `--overwrite` | Allows updating an existing parameter. Without this flag, `put-parameter` fails if the parameter already exists. |
| `--with-decryption` | Decrypts a `SecureString` parameter on retrieval. Without this flag, the encrypted ciphertext is returned. |
| `--path` | The hierarchical prefix used by `get-parameters-by-path` to fetch a subtree of parameters. |
| `--recursive` | Used with `get-parameters-by-path` to include all nested sub-paths under the given prefix. |
| `--query` | JMESPath expression to filter and reshape the response output. |

## How to Run the Demo
```bash
cd services/08-management/ssm
bash demo.sh
```

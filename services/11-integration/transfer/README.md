# AWS Transfer Family

## What is it?
AWS Transfer Family is a fully managed file transfer service that lets you move files into and out of AWS storage (S3 or EFS) over standard protocols: SFTP, FTPS, FTP, and AS2. You create a Transfer server endpoint, and your existing file-transfer clients connect to it exactly as they would to an on-premises FTP/SFTP server — no code changes required. AWS handles infrastructure, availability, and scaling while you keep control of user authentication (service-managed SSH keys, custom Lambda-backed IdP, or Active Directory). It is the right choice for migrating legacy file-transfer workflows to the cloud without rewriting clients.

## Key Concepts
- **Server** — a Transfer endpoint that listens for inbound connections on a chosen protocol (SFTP, FTPS, FTP, or AS2) and an endpoint type (PUBLIC or VPC).
- **Protocol** — the file-transfer standard the server speaks; SFTP (SSH-based) is most common; AS2 is used for EDI/B2B exchanges.
- **User** — a named account on a server; each user has an IAM role that controls which S3 paths they can read/write and a home directory mapping.
- **Home Directory** — the S3 bucket path (or EFS path) that appears as the root when the user connects; can be logical (restricted view) or path-based.
- **Identity Provider** — how users authenticate: `SERVICE_MANAGED` (SSH public keys stored in Transfer), `AWS_DIRECTORY_SERVICE` (AD), or `AWS_LAMBDA` (custom auth logic).
- **SSH Public Key** — the RSA/Ed25519 public key uploaded for a service-managed user; the corresponding private key is held by the connecting client.

## When to Use
- **Legacy SFTP migration** — replace on-premises SFTP servers with an AWS-managed endpoint that stores files directly in S3, eliminating server maintenance.
- **Partner file exchange** — receive EDI documents or large data files from external partners using AS2 or SFTP with per-partner user accounts and isolated S3 prefixes.
- **Automated ETL ingestion** — have data suppliers drop CSV/XML files into a Transfer server; trigger downstream Lambda or Glue jobs via S3 event notifications.
- **Compliance-driven file transfer** — meet HIPAA, PCI-DSS, or SOC 2 requirements for encrypted in-transit file transfer without building custom infrastructure.

## CLI Quick Reference (awslocal)

### Create a server
```bash
awslocal transfer create-server \
  --protocols SFTP \
  --endpoint-type PUBLIC \
  --identity-provider-type SERVICE_MANAGED
```

### List servers
```bash
awslocal transfer list-servers \
  --query 'Servers[].{ServerId:ServerId,State:State,Protocols:Protocols}' \
  --output table
```

### Describe a server
```bash
awslocal transfer describe-server \
  --server-id s-0123456789abcdef0
```

### Create a user
```bash
awslocal transfer create-user \
  --server-id s-0123456789abcdef0 \
  --user-name alice \
  --role arn:aws:iam::000000000000:role/transfer-s3-role \
  --home-directory /my-transfer-bucket/home/alice
```

### List users on a server
```bash
awslocal transfer list-users \
  --server-id s-0123456789abcdef0 \
  --query 'Users[].{UserName:UserName,HomeDirectory:HomeDirectory}' \
  --output table
```

### Describe a user
```bash
awslocal transfer describe-user \
  --server-id s-0123456789abcdef0 \
  --user-name alice
```

### Import an SSH public key for a user
```bash
awslocal transfer import-ssh-public-key \
  --server-id s-0123456789abcdef0 \
  --user-name alice \
  --ssh-public-key-body "ssh-ed25519 AAAAC3Nza... alice@laptop"
```

### Delete a user
```bash
awslocal transfer delete-user \
  --server-id s-0123456789abcdef0 \
  --user-name alice
```

### Delete a server
```bash
awslocal transfer delete-server \
  --server-id s-0123456789abcdef0
```

## Example Walkthrough

1. **Create the S3 bucket** that will act as the file storage backend.
   ```bash
   awslocal s3 mb s3://transfer-demo-bucket
   ```

2. **Create an IAM role** that allows the Transfer service to read and write the S3 bucket.
   ```bash
   awslocal iam create-role --role-name transfer-s3-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"transfer.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   awslocal iam attach-role-policy --role-name transfer-s3-role \
     --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
   ```

3. **Create the SFTP server** — a public endpoint with service-managed user authentication.
   ```bash
   SERVER_ID=$(awslocal transfer create-server \
     --protocols SFTP \
     --endpoint-type PUBLIC \
     --identity-provider-type SERVICE_MANAGED \
     --output text --query 'ServerId')
   echo "Server ID: $SERVER_ID"
   ```

4. **Add an SFTP user** — map the user to their own home prefix inside the bucket.
   ```bash
   awslocal transfer create-user \
     --server-id "$SERVER_ID" \
     --user-name alice \
     --role arn:aws:iam::000000000000:role/transfer-s3-role \
     --home-directory /transfer-demo-bucket/home/alice
   echo "User 'alice' created"
   ```

5. **Describe the server** — confirm it is in ONLINE state with the SFTP protocol.
   ```bash
   awslocal transfer describe-server \
     --server-id "$SERVER_ID" \
     --query 'Server.{Id:ServerId,State:State,Protocols:Protocols}' \
     --output table
   ```

6. **List users** — verify the user appears on the server.
   ```bash
   awslocal transfer list-users \
     --server-id "$SERVER_ID" \
     --query 'Users[].{UserName:UserName,HomeDirectory:HomeDirectory}' \
     --output table
   ```

7. **Clean up** — delete the user and then the server.
   ```bash
   awslocal transfer delete-user --server-id "$SERVER_ID" --user-name alice
   awslocal transfer delete-server --server-id "$SERVER_ID"
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--protocols` | Transfer protocol(s) the server supports | `SFTP`, `FTPS`, `FTP`, `AS2` |
| `--endpoint-type` | Network exposure of the server | `PUBLIC` or `VPC` |
| `--identity-provider-type` | How users authenticate | `SERVICE_MANAGED`, `AWS_DIRECTORY_SERVICE`, `AWS_LAMBDA` |
| `--server-id` | ID of the Transfer server (format `s-...`) | `s-0123456789abcdef0` |
| `--user-name` | Login name for the SFTP/FTP user | `alice` |
| `--role` | IAM role ARN the user assumes for S3/EFS access | `arn:aws:iam::000000000000:role/transfer-s3-role` |
| `--home-directory` | S3 path that becomes the user's root directory | `/my-bucket/home/alice` |
| `--home-directory-type` | `PATH` (transparent) or `LOGICAL` (mapped with restricted view) | `LOGICAL` |
| `--ssh-public-key-body` | OpenSSH-format public key string for the user | `ssh-ed25519 AAAA...` |
| `--security-policy-name` | TLS/cipher policy applied to the endpoint | `TransferSecurityPolicy-2023-05` |

## How to Run the Demo

```bash
cd services/11-integration/transfer
bash demo.sh
```

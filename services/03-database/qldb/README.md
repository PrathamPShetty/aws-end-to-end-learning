# Amazon QLDB (Quantum Ledger Database)

## What is it?
Amazon QLDB is a fully managed ledger database that provides a transparent, immutable, and cryptographically verifiable transaction log owned by a central trusted authority. Unlike traditional databases, QLDB maintains a complete and permanent history of every change ever made to your data — no record can be deleted or altered retroactively. It is purpose-built for applications where you need an authoritative, auditable record of data changes, such as financial transaction histories, supply chain audit trails, or regulatory compliance records. QLDB uses a SQL-like query language called PartiQL and guarantees that every document revision is cryptographically chained using a hash tree (SHA-256), making tampering detectable.

## Key Concepts
- **Ledger** — The top-level QLDB resource; a named, serverless database that contains tables and an immutable journal.
- **Journal** — An append-only, cryptographically chained log of every committed transaction ever written to the ledger; it is the source of truth from which tables are derived.
- **Table** — A collection of Amazon Ion documents within a ledger; queryable via PartiQL. Rows are called "documents".
- **Document Revision** — Each version of a document after an update; QLDB retains every revision, forming a full audit history per document.
- **Digest** — A cryptographic hash (SHA-256) of the entire journal that can be used to verify the integrity of the complete ledger history.
- **Journal Export** — A batch export of journal blocks to Amazon S3 for long-term archival, downstream processing, or compliance reporting.

## When to Use
- **Financial ledgers** — Record every debit, credit, and balance update in a bank or fintech application with a tamper-proof history.
- **Supply chain tracking** — Log every transfer-of-custody event for goods across a supply chain so that the full provenance of an item is always verifiable.
- **HR and payroll audit trails** — Maintain an immutable record of every change to employee salaries, roles, and benefits for compliance and auditing.
- **Regulatory compliance systems** — Store health records, insurance claims, or legal documents where regulators require proof that data has not been altered.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create ledger | `awslocal qldb create-ledger --name demo-ledger --permissions-mode ALLOW_ALL` |
| Describe ledger | `awslocal qldb describe-ledger --name demo-ledger` |
| List ledgers | `awslocal qldb list-ledgers` |
| Get digest | `awslocal qldb get-digest --name demo-ledger` |
| Export journal to S3 | `awslocal qldb export-journal-to-s3 --name demo-ledger --inclusive-start-time 2024-01-01T00:00:00Z --exclusive-end-time 2024-01-02T00:00:00Z --s3-export-configuration "Bucket=my-bucket,Prefix=exports/,EncryptionConfiguration={ObjectEncryptionType=NO_ENCRYPTION}" --role-arn arn:aws:iam::000000000000:role/qldb-role` |
| List journal exports | `awslocal qldb list-journal-s3-exports-for-ledger --name demo-ledger` |
| Update ledger | `awslocal qldb update-ledger --name demo-ledger --no-deletion-protection` |
| Delete ledger | `awslocal qldb delete-ledger --name demo-ledger` |

## Example Walkthrough

1. **Create an S3 bucket** to hold journal exports:
   ```bash
   awslocal s3 mb s3://qldb-journal-exports --region us-east-1
   ```

2. **Create a QLDB ledger** with `ALLOW_ALL` permissions mode (suitable for single-owner use):
   ```bash
   awslocal qldb create-ledger \
     --name demo-ledger \
     --permissions-mode ALLOW_ALL
   ```

3. **Describe the ledger** to confirm it is in the `ACTIVE` state:
   ```bash
   awslocal qldb describe-ledger \
     --name demo-ledger \
     --query '{Name:Name,State:State,DeletionProtection:DeletionProtection,ARN:Arn}' \
     --output table
   ```

4. **Retrieve the cryptographic digest** to capture the current verifiable state of the journal:
   ```bash
   awslocal qldb get-digest --name demo-ledger
   ```

5. **Export the journal to S3** for archival or downstream processing:
   ```bash
   START=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u --date='1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
   END=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
   awslocal qldb export-journal-to-s3 \
     --name demo-ledger \
     --inclusive-start-time "$START" \
     --exclusive-end-time "$END" \
     --s3-export-configuration "Bucket=qldb-journal-exports,Prefix=exports/,EncryptionConfiguration={ObjectEncryptionType=NO_ENCRYPTION}" \
     --role-arn "arn:aws:iam::000000000000:role/qldb-export-role"
   ```

6. **List all journal S3 exports** to monitor export job status:
   ```bash
   awslocal qldb list-journal-s3-exports-for-ledger \
     --name demo-ledger
   ```

7. **List all ledgers** in the account to confirm the ledger exists:
   ```bash
   awslocal qldb list-ledgers \
     --query 'Ledgers[*].{Name:Name,State:State}' \
     --output table
   ```

8. **Disable deletion protection** and delete the ledger when finished:
   ```bash
   awslocal qldb update-ledger --name demo-ledger --no-deletion-protection
   awslocal qldb delete-ledger --name demo-ledger
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--name` | Unique name for the ledger (1–32 alphanumeric characters or hyphens). |
| `--permissions-mode` | `ALLOW_ALL` gives all users full access; `STANDARD` uses fine-grained IAM table-level permissions. |
| `--deletion-protection` | When `true` (default), prevents the ledger from being deleted. Must be disabled before deletion. |
| `--inclusive-start-time` | ISO-8601 timestamp for the start of a journal export range (inclusive). |
| `--exclusive-end-time` | ISO-8601 timestamp for the end of a journal export range (exclusive). |
| `--s3-export-configuration` | Destination bucket, prefix, and encryption settings for a journal S3 export. |
| `--role-arn` | IAM role ARN that QLDB assumes to write journal blocks to the S3 bucket. |
| `--kms-key` | KMS key ARN to encrypt the ledger at rest (optional; defaults to AWS-managed key). |
| `--tags` | Key-value metadata tags to attach to the ledger for cost allocation or organisation. |

## How to Run the Demo
```bash
cd services/03-database/qldb
bash demo.sh
```

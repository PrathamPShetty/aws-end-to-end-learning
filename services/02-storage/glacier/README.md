# Amazon S3 Glacier

## What is it?
Amazon S3 Glacier is a secure, durable, and extremely low-cost cloud storage service designed for long-term data archival and backup. Unlike S3, Glacier is not intended for frequent access — retrieval can take minutes to hours depending on the retrieval tier you choose. You organize archives into **vaults** (similar to S3 buckets), and each uploaded file becomes an **archive** with a system-assigned ID. Its main benefit is that it can store massive amounts of rarely-accessed data at a fraction of the cost of S3, making it ideal for regulatory compliance archives, disaster recovery copies, and long-term backups.

## Key Concepts
- **Vault** — A container for archives, similar to an S3 bucket. You create one vault per region per account and control access via vault access policies.
- **Archive** — Any data (a file, ZIP, video, database dump) stored in Glacier. Each archive gets a unique, system-generated Archive ID upon upload.
- **Inventory** — A listing of all archives stored in a vault. Glacier generates this asynchronously via a retrieval job.
- **Job** — An asynchronous operation to either retrieve an archive or generate a vault inventory. Jobs take time to complete (minutes to hours on real AWS).
- **Retrieval Tier** — The speed vs. cost tradeoff for retrievals: Expedited (1–5 min), Standard (3–5 hrs), Bulk (5–12 hrs).
- **Vault Lock** — A compliance feature that enforces a write-once-read-many (WORM) policy, preventing deletion of archives for a specified period.

## When to Use
- **Long-term regulatory compliance** — Store financial records, medical data, or legal documents that must be retained for 7–10+ years.
- **Database and system backups** — Archive nightly or weekly database dumps that you only need if disaster strikes.
- **Media master files** — Keep original, unedited video or audio masters that are rarely accessed but must never be lost.
- **Replacing tape storage** — Migrate away from physical tape libraries to a durable, managed cloud archive at lower total cost.

## CLI Quick Reference (awslocal)

### Vault operations
| Operation | Command |
|---|---|
| Create a vault | `awslocal glacier create-vault --account-id - --vault-name my-vault` |
| List vaults | `awslocal glacier list-vaults --account-id -` |
| Describe a vault | `awslocal glacier describe-vault --account-id - --vault-name my-vault` |
| Delete a vault | `awslocal glacier delete-vault --account-id - --vault-name my-vault` |

### Archive operations
| Operation | Command |
|---|---|
| Upload an archive | `awslocal glacier upload-archive --account-id - --vault-name my-vault --body backup.tar.gz --archive-description "DB backup 2026-06-07"` |
| Delete an archive | `awslocal glacier delete-archive --account-id - --vault-name my-vault --archive-id <archive-id>` |

### Job operations
| Operation | Command |
|---|---|
| Start inventory retrieval | `awslocal glacier initiate-job --account-id - --vault-name my-vault --job-parameters '{"Type":"inventory-retrieval"}'` |
| Start archive retrieval | `awslocal glacier initiate-job --account-id - --vault-name my-vault --job-parameters '{"Type":"archive-retrieval","ArchiveId":"<archive-id>"}'` |
| List jobs | `awslocal glacier list-jobs --account-id - --vault-name my-vault` |
| Get job output | `awslocal glacier get-job-output --account-id - --vault-name my-vault --job-id <job-id> output.json` |

> Note: `--account-id -` tells the CLI to use the caller's own account ID automatically.

## Example Walkthrough

1. **Create a vault** — Make a new Glacier vault to hold your archives.
   ```bash
   awslocal glacier create-vault \
     --account-id - \
     --vault-name my-archive-vault
   ```

2. **List vaults** — Confirm the vault was created.
   ```bash
   awslocal glacier list-vaults \
     --account-id - \
     --query 'VaultList[].{Name:VaultName,Archives:NumberOfArchives}' \
     --output table
   ```

3. **Upload an archive** — Send a file to the vault; capture the returned Archive ID.
   ```bash
   ARCHIVE_ID=$(awslocal glacier upload-archive \
     --account-id - \
     --vault-name my-archive-vault \
     --body ./database-backup.tar.gz \
     --archive-description "DB backup 2026-06-07" \
     --query 'archiveId' --output text)
   echo "Archive ID: $ARCHIVE_ID"
   ```

4. **Initiate an inventory retrieval job** — Request a listing of all archives in the vault.
   ```bash
   awslocal glacier initiate-job \
     --account-id - \
     --vault-name my-archive-vault \
     --job-parameters '{"Type":"inventory-retrieval","Description":"Full vault inventory"}'
   ```

5. **List jobs** — Check the status of running or completed jobs.
   ```bash
   awslocal glacier list-jobs \
     --account-id - \
     --vault-name my-archive-vault \
     --query 'JobList[].{JobId:JobId,Type:Action,Status:StatusCode}' \
     --output table
   ```

6. **Delete the archive** — Remove the archive before deleting the vault.
   ```bash
   awslocal glacier delete-archive \
     --account-id - \
     --vault-name my-archive-vault \
     --archive-id "$ARCHIVE_ID"
   ```

7. **Delete the vault** — Remove the now-empty vault.
   ```bash
   awslocal glacier delete-vault \
     --account-id - \
     --vault-name my-archive-vault
   ```

## Important Flags & Options

| Flag / Option | Used With | Description |
|---|---|---|
| `--account-id` | All commands | AWS account ID. Use `-` to default to the caller's account. |
| `--vault-name` | All commands | Name of the target vault. |
| `--body` | `upload-archive` | Path to the local file to upload. |
| `--archive-description` | `upload-archive` | Human-readable label for the archive (searchable in inventory). |
| `--archive-id` | `delete-archive`, `initiate-job` | System-assigned ID returned when an archive was uploaded. |
| `--job-parameters` | `initiate-job` | JSON object specifying the job type (`inventory-retrieval` or `archive-retrieval`). |
| `--job-id` | `get-job-output`, `describe-job` | ID of the job to inspect or download output from. |
| `--query` | Any command | JMESPath expression to filter/reshape the JSON response. |
| `--output table` | Any command | Renders results as a human-readable table. |

## How to Run the Demo

```bash
cd services/02-storage/glacier
bash demo.sh
```

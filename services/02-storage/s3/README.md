# Amazon S3 — Simple Storage Service

## What is it?
Amazon S3 (Simple Storage Service) is an object storage service that lets you store and retrieve any amount of data from anywhere on the internet. You organize data into **buckets** (top-level containers) and store individual files as **objects**, each identified by a unique **key**. S3 is the go-to choice for storing application assets, backups, logs, and static website files because it scales automatically and offers high durability (99.999999999% — "eleven nines"). Its main benefit is that you never manage servers or disks — you just put data in and get it back whenever you need it.

## Key Concepts
- **Bucket** — A globally named container that holds objects. Every bucket has a unique name across all of AWS.
- **Object** — A file stored in a bucket. Made up of the data itself plus metadata.
- **Key** — The full path/name of an object within a bucket (e.g. `images/logo.png`). Keys look like file paths but S3 is flat — folders are just key prefixes.
- **Versioning** — A bucket-level feature that keeps every version of every object. Protects against accidental deletes and overwrites.
- **ACL (Access Control List)** — Per-object or per-bucket permissions defining who can read or write.
- **Presigned URL** — A time-limited URL that grants temporary access to a private object without requiring AWS credentials.

## When to Use
- **Static website hosting** — Serve HTML, CSS, JS, and images directly from a bucket as a website endpoint.
- **Application backups and archives** — Store database dumps, log files, and system snapshots cheaply and durably.
- **Data lake / analytics staging** — Land raw data files (CSV, JSON, Parquet) before processing with Athena, Glue, or EMR.
- **Media storage and distribution** — Store images, videos, and documents uploaded by end users in a web or mobile app.

## CLI Quick Reference (awslocal)

### Bucket operations
| Operation | Command |
|---|---|
| Create bucket | `awslocal s3api create-bucket --bucket my-bucket` |
| List all buckets | `awslocal s3 ls` |
| Delete empty bucket | `awslocal s3api delete-bucket --bucket my-bucket` |
| Delete bucket and all contents | `awslocal s3 rb s3://my-bucket --force` |

### Object operations
| Operation | Command |
|---|---|
| Upload a file | `awslocal s3 cp report.pdf s3://my-bucket/reports/report.pdf` |
| Upload from stdin | `echo "hello" \| awslocal s3 cp - s3://my-bucket/hello.txt` |
| List objects in bucket | `awslocal s3 ls s3://my-bucket --recursive` |
| Download a file | `awslocal s3 cp s3://my-bucket/reports/report.pdf ./report.pdf` |
| Delete an object | `awslocal s3 rm s3://my-bucket/reports/report.pdf` |
| Sync a local folder | `awslocal s3 sync ./local-dir s3://my-bucket/backup/` |

### Bucket configuration
| Operation | Command |
|---|---|
| Enable versioning | `awslocal s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled` |
| List object versions | `awslocal s3api list-object-versions --bucket my-bucket` |
| Get bucket policy | `awslocal s3api get-bucket-policy --bucket my-bucket` |

## Example Walkthrough

1. **Create a bucket** — Make a new S3 bucket to hold your files.
   ```bash
   awslocal s3api create-bucket --bucket my-app-bucket
   ```

2. **Enable versioning** — Turn on versioning so every upload is preserved as a separate version.
   ```bash
   awslocal s3api put-bucket-versioning \
     --bucket my-app-bucket \
     --versioning-configuration Status=Enabled
   ```

3. **Upload a file** — Copy a local file into the bucket under a key.
   ```bash
   awslocal s3 cp ./config.json s3://my-app-bucket/configs/config.json
   ```

4. **Overwrite the file** — Upload again; versioning stores both copies.
   ```bash
   echo '{"env":"prod"}' | awslocal s3 cp - s3://my-app-bucket/configs/config.json
   ```

5. **List all versions of the object** — See both versions and their version IDs.
   ```bash
   awslocal s3api list-object-versions \
     --bucket my-app-bucket \
     --query 'Versions[].{Key:Key,VersionId:VersionId,IsLatest:IsLatest}' \
     --output table
   ```

6. **Download the latest version** — Pull the current file back to your local machine.
   ```bash
   awslocal s3 cp s3://my-app-bucket/configs/config.json ./config-downloaded.json
   ```

7. **Clean up** — Delete the bucket and all its contents.
   ```bash
   awslocal s3 rb s3://my-app-bucket --force
   ```

## Important Flags & Options

| Flag / Option | Used With | Description |
|---|---|---|
| `--bucket` | `s3api` commands | Target bucket name |
| `--key` | `s3api get-object`, `put-object` | Object key (path inside bucket) |
| `--body` | `s3api put-object` | Local file to upload |
| `--recursive` | `s3 ls`, `s3 cp`, `s3 rm` | Applies the command to all objects under a prefix |
| `--force` | `s3 rb` | Deletes all objects first, then removes the bucket |
| `--versioning-configuration` | `put-bucket-versioning` | Enable or Suspend versioning (`Status=Enabled`) |
| `--query` | Any command | JMESPath filter to shape JSON output |
| `--output table` | Any command | Renders results as a human-readable table |
| `--sse` | `s3 cp`, `s3 sync` | Server-side encryption (`aws:kms` or `AES256`) |
| `--acl` | `s3 cp`, `s3api put-object` | Canned ACL (`private`, `public-read`, etc.) |

## How to Run the Demo

```bash
cd services/02-storage/s3
bash demo.sh
```

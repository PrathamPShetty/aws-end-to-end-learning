# Amazon Kinesis Data Firehose

## What is it?
Amazon Kinesis Data Firehose (now also called Amazon Data Firehose) is a fully managed service that automatically loads streaming data into data lakes, data stores, and analytics services — with zero administration. Unlike Kinesis Data Streams where you manage shards and consumers, Firehose handles batching, compression, encryption, and delivery entirely on its own. You put records in, and Firehose buffers them (by size or time) and delivers them to a destination such as S3, Redshift, OpenSearch, or Splunk. It is the simplest path from raw events to a queryable data store.

## Key Concepts
- **Delivery Stream** — The core resource: a named pipeline with a source and a destination. You put records into it and Firehose handles the rest.
- **Destination** — Where Firehose delivers data. Supported targets include Amazon S3, Redshift, OpenSearch Service, and HTTP endpoints.
- **Buffering Hints** — Configuration that controls when a batch is flushed: either when the buffer reaches a size threshold (MB) or a time threshold (seconds), whichever comes first.
- **Prefix / S3 Prefix** — The S3 key prefix prepended to all objects written to the bucket; supports dynamic partitioning with timestamps.
- **Transformation** — An optional Lambda function that Firehose invokes to transform records before delivery (e.g., parse, enrich, filter).
- **DirectPut** — The delivery stream type where producers call `put-record` directly (as opposed to sourcing from a Kinesis Data Stream).

## When to Use
- **Log archival to S3** — continuously deliver application logs or CloudWatch logs to S3 for long-term storage and Athena querying, with no custom consumer code.
- **Data lake ingestion** — stream clickstream events or IoT sensor readings into partitioned S3 paths in near-real time.
- **Redshift loading** — load high-volume transactional or event data into a Redshift data warehouse automatically, without managing COPY jobs.
- **Security event storage** — pipe VPC flow logs or WAF logs to S3 or OpenSearch for SIEM analysis.

## CLI Quick Reference (awslocal)

### Delivery stream operations

| Action | Command |
|---|---|
| Create delivery stream (to S3) | `awslocal firehose create-delivery-stream --delivery-stream-name my-stream --delivery-stream-type DirectPut --s3-destination-configuration '{"RoleARN":"arn:aws:iam::000000000000:role/role","BucketARN":"arn:aws:s3:::my-bucket","Prefix":"events/"}'` |
| List delivery streams | `awslocal firehose list-delivery-streams` |
| Describe delivery stream | `awslocal firehose describe-delivery-stream --delivery-stream-name my-stream` |
| Delete delivery stream | `awslocal firehose delete-delivery-stream --delivery-stream-name my-stream` |

### Record operations

| Action | Command |
|---|---|
| Put single record | `awslocal firehose put-record --delivery-stream-name my-stream --record '{"Data":"<base64>"}'` |
| Put batch of records | `awslocal firehose put-record-batch --delivery-stream-name my-stream --records '[{"Data":"<base64>"},{"Data":"<base64>"}]'` |

## Example Walkthrough

1. **Create an S3 bucket as the delivery destination** — Firehose will write batched files here.
   ```bash
   awslocal s3 mb s3://demo-firehose-bucket
   ```

2. **Create a Firehose delivery stream targeting the S3 bucket** — configure buffering so records flush after 60 seconds or 1 MB, whichever comes first.
   ```bash
   awslocal firehose create-delivery-stream \
     --delivery-stream-name demo-firehose-stream \
     --delivery-stream-type DirectPut \
     --s3-destination-configuration '{
       "RoleARN": "arn:aws:iam::000000000000:role/firehose-role",
       "BucketARN": "arn:aws:s3:::demo-firehose-bucket",
       "Prefix": "events/",
       "BufferingHints": {"SizeInMBs": 1, "IntervalInSeconds": 60},
       "CompressionFormat": "UNCOMPRESSED"
     }'
   ```

3. **Wait for the delivery stream to become ACTIVE** — it must be ready before accepting records.
   ```bash
   until [ "$(awslocal firehose describe-delivery-stream \
     --delivery-stream-name demo-firehose-stream \
     --output text --query 'DeliveryStreamDescription.DeliveryStreamStatus')" = "ACTIVE" ]; do
     echo "Waiting..."; sleep 1
   done
   ```

4. **Put a single record** — the data blob must be base64-encoded.
   ```bash
   awslocal firehose put-record \
     --delivery-stream-name demo-firehose-stream \
     --record '{"Data":"'$(echo '{"event":"login","userId":"u1","ts":"2026-01-01T00:00:00Z"}' | base64)'"}'
   ```

5. **Put a batch of records in one call** — more efficient; Firehose accepts up to 500 records or 4 MB per batch call.
   ```bash
   awslocal firehose put-record-batch \
     --delivery-stream-name demo-firehose-stream \
     --records '[
       {"Data":"'$(echo '{"event":"page_view","page":"/home"}' | base64)'"},
       {"Data":"'$(echo '{"event":"click","element":"buy-button"}' | base64)'"}
     ]'
   ```

6. **Verify delivery — list objects written to S3** — after the buffer flushes, objects appear under the prefix.
   ```bash
   awslocal s3 ls s3://demo-firehose-bucket/events/ --recursive
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--delivery-stream-name` | Name of the Firehose delivery stream. |
| `--delivery-stream-type` | `DirectPut` (producers call the API directly) or `KinesisStreamAsSource` (reads from a Kinesis stream). |
| `--s3-destination-configuration` | JSON block specifying `BucketARN`, `RoleARN`, `Prefix`, buffering, and compression. |
| `BufferingHints.SizeInMBs` | Flush when the buffer reaches this size (1–128 MB). |
| `BufferingHints.IntervalInSeconds` | Flush after this many seconds (60–900 s). |
| `CompressionFormat` | `UNCOMPRESSED`, `GZIP`, `ZIP`, `Snappy`. |
| `--record '{"Data":"<base64>"}'` | Single record payload; `Data` must be base64-encoded. |
| `--records '[...]'` | Array of records for `put-record-batch` (max 500 records, 4 MB total). |

## How to Run the Demo

```bash
cd services/04-messaging/firehose
bash demo.sh
```

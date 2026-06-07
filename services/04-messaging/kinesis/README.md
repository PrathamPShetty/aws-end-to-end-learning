# Amazon Kinesis Data Streams

## What is it?
Amazon Kinesis Data Streams is a massively scalable, real-time data streaming service designed to continuously capture gigabytes of data per second from hundreds of thousands of sources. Unlike SQS where a message is consumed once and deleted, Kinesis retains records for up to 365 days so multiple consumers can read the same data independently. Data is partitioned across shards, each providing 1 MB/s ingest and 2 MB/s read throughput. It is the foundation for real-time analytics pipelines, event sourcing, and stream processing with frameworks like Apache Flink or AWS Lambda.

## Key Concepts
- **Stream** — A named, ordered sequence of data records; capacity is determined by the number of shards.
- **Shard** — The base throughput unit. Each shard handles up to 1 MB/s write (1000 records/s) and 2 MB/s read. You add shards to scale.
- **Record** — The unit of data: a partition key, a sequence number (assigned by Kinesis), and a data blob (up to 1 MB).
- **Partition Key** — A string that determines which shard a record goes to (via MD5 hash). Use a high-cardinality value (user ID, session ID) for even distribution.
- **Shard Iterator** — A cursor pointing to a position within a shard. Required to call `get-records`. Types: `TRIM_HORIZON` (oldest), `LATEST`, `AT_SEQUENCE_NUMBER`, `AT_TIMESTAMP`.
- **Retention Period** — How long records are kept in the stream (default 24 h, max 365 days).

## When to Use
- **Clickstream and event analytics** — ingest millions of user-interaction events per second and process them in real time with Lambda or Kinesis Data Analytics.
- **Log and metrics aggregation** — stream application logs or IoT sensor data from thousands of devices into a central pipeline for monitoring.
- **Event sourcing** — replay the full ordered history of events in a shard for audit, debugging, or rebuilding application state.
- **Real-time fraud detection** — analyze financial transactions as they arrive and trigger alerts within seconds.

## CLI Quick Reference (awslocal)

### Stream operations

| Action | Command |
|---|---|
| Create stream | `awslocal kinesis create-stream --stream-name my-stream --shard-count 2` |
| List streams | `awslocal kinesis list-streams` |
| Describe stream | `awslocal kinesis describe-stream-summary --stream-name my-stream` |
| List shards | `awslocal kinesis list-shards --stream-name my-stream` |
| Update shard count | `awslocal kinesis update-shard-count --stream-name my-stream --target-shard-count 4 --scaling-type UNIFORM_SCALING` |
| Delete stream | `awslocal kinesis delete-stream --stream-name my-stream` |

### Record operations

| Action | Command |
|---|---|
| Put single record | `awslocal kinesis put-record --stream-name my-stream --data "$(echo '{"userId":"u1"}' \| base64)" --partition-key "user-u1"` |
| Put multiple records | `awslocal kinesis put-records --stream-name my-stream --records '[{"Data":"<base64>","PartitionKey":"k1"}]'` |
| Get shard iterator | `awslocal kinesis get-shard-iterator --stream-name my-stream --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON` |
| Get records | `awslocal kinesis get-records --shard-iterator <ITERATOR> --limit 100` |

## Example Walkthrough

1. **Create a Kinesis stream with 2 shards** — two parallel lanes of ingestion capacity.
   ```bash
   awslocal kinesis create-stream \
     --stream-name demo-events-stream \
     --shard-count 2
   ```

2. **Wait for the stream to become ACTIVE** — poll until ready before writing.
   ```bash
   until [ "$(awslocal kinesis describe-stream-summary \
     --stream-name demo-events-stream \
     --output text --query 'StreamDescriptionSummary.StreamStatus')" = "ACTIVE" ]; do
     echo "Waiting..."; sleep 1
   done
   ```

3. **Put a record into the stream** — the data must be base64-encoded.
   ```bash
   awslocal kinesis put-record \
     --stream-name demo-events-stream \
     --data "$(echo '{"userId":"u1","action":"page_view","page":"/home"}' | base64)" \
     --partition-key "user-u1"
   ```

4. **Put multiple records in a single call** — more efficient for bulk ingestion.
   ```bash
   awslocal kinesis put-records \
     --stream-name demo-events-stream \
     --records '[
       {"Data":"'$(echo '{"userId":"u2","action":"click"}' | base64)'","PartitionKey":"user-u2"},
       {"Data":"'$(echo '{"userId":"u3","action":"purchase"}' | base64)'","PartitionKey":"user-u3"}
     ]'
   ```

5. **Obtain a shard iterator starting at the oldest record** — your read cursor.
   ```bash
   SHARD_ID=$(awslocal kinesis list-shards \
     --stream-name demo-events-stream \
     --output text --query 'Shards[0].ShardId')
   ITERATOR=$(awslocal kinesis get-shard-iterator \
     --stream-name demo-events-stream \
     --shard-id "$SHARD_ID" \
     --shard-iterator-type TRIM_HORIZON \
     --output text --query 'ShardIterator')
   ```

6. **Read records and decode the data** — each record's `Data` field is base64-encoded.
   ```bash
   awslocal kinesis get-records \
     --shard-iterator "$ITERATOR" \
     --limit 10 | \
     python3 -c "import sys,json,base64; d=json.load(sys.stdin);
   [print(base64.b64decode(r['Data']).decode()) for r in d.get('Records',[])]"
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--stream-name` | Name of the Kinesis stream. |
| `--shard-count` | Number of shards at creation time. More shards = more throughput. |
| `--partition-key` | Determines which shard a record routes to. Use high-cardinality values. |
| `--data` | Base64-encoded record payload (max 1 MB per record). |
| `--shard-iterator-type` | Read position: `TRIM_HORIZON`, `LATEST`, `AT_SEQUENCE_NUMBER`, `AT_TIMESTAMP`. |
| `--limit` | Max records to return from `get-records` (up to 10000, but limited to 10 MB). |
| `--starting-sequence-number` | Used with `AT_SEQUENCE_NUMBER` iterator type to resume reading. |
| `--retention-period-hours` | Set via `increase-stream-retention-period` (24–8760 h). |

## How to Run the Demo

```bash
cd services/04-messaging/kinesis
bash demo.sh
```

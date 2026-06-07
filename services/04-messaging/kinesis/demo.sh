#!/bin/bash
# ============================================================
# Kinesis Data Streams Demo
# Purpose: Create stream, put records, get records via shard iterator
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

STREAM_NAME="demo-events-stream"

echo "==> Creating Kinesis stream (2 shards)..."
awslocal kinesis create-stream --stream-name "$STREAM_NAME" --shard-count 2 || true

echo "==> Waiting for stream to become ACTIVE..."
for i in $(seq 1 10); do
  STATUS=$(awslocal kinesis describe-stream-summary --stream-name "$STREAM_NAME" \
    --output text --query 'StreamDescriptionSummary.StreamStatus')
  echo "  Status: $STATUS"
  [ "$STATUS" = "ACTIVE" ] && break
  sleep 1
done

echo "==> Putting records into stream..."
awslocal kinesis put-record \
  --stream-name "$STREAM_NAME" \
  --data "$(echo '{"userId":"u1","action":"page_view","page":"/home"}' | base64)" \
  --partition-key "user-u1"

awslocal kinesis put-records \
  --stream-name "$STREAM_NAME" \
  --records '[
    {"Data":"eyJ1c2VySWQiOiJ1MiIsImFjdGlvbiI6ImNsaWNrIn0=","PartitionKey":"user-u2"},
    {"Data":"eyJ1c2VySWQiOiJ1MyIsImFjdGlvbiI6InB1cmNoYXNlIn0=","PartitionKey":"user-u3"}
  ]'
echo "Records written."

echo "==> Reading records from first shard..."
SHARD_ID=$(awslocal kinesis list-shards --stream-name "$STREAM_NAME" \
  --output text --query 'Shards[0].ShardId')
echo "Shard: $SHARD_ID"

ITERATOR=$(awslocal kinesis get-shard-iterator \
  --stream-name "$STREAM_NAME" \
  --shard-id "$SHARD_ID" \
  --shard-iterator-type TRIM_HORIZON \
  --output text --query 'ShardIterator')

echo "==> Records from shard:"
awslocal kinesis get-records --shard-iterator "$ITERATOR" --limit 10 | \
  python3 -c "import sys,json,base64; d=json.load(sys.stdin); [print('  Data:', base64.b64decode(r['Data']).decode()) for r in d.get('Records',[])]"

echo "==> Stream summary:"
awslocal kinesis describe-stream-summary --stream-name "$STREAM_NAME" \
  --output text --query 'StreamDescriptionSummary.{Name:StreamName,Status:StreamStatus,Shards:OpenShardCount}'
echo "==> Kinesis demo complete."

#!/bin/bash
# ═══════════════════════════════════════════════════════
#  Timestream — Serverless time series database demo
#  Creates a database + table, writes time-series records,
#  and runs a SELECT query via query API
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Timestream Demo                        ║"
echo "╚══════════════════════════════════════════╝"

# ── Create Timestream database ───────────────────
echo ""
echo "▶ Creating Timestream database..."
awslocal timestream-write create-database \
  --database-name demo_metrics \
  > /dev/null 2>&1 || true
echo "  ✓ Database: demo_metrics"

# ── Create table ─────────────────────────────────
echo ""
echo "▶ Creating Timestream table..."
awslocal timestream-write create-table \
  --database-name demo_metrics \
  --table-name cpu_usage \
  --retention-properties "MemoryStoreRetentionPeriodInHours=24,MagneticStoreRetentionPeriodInDays=7" \
  > /dev/null 2>&1 || true
echo "  ✓ Table: cpu_usage"

# ── Write records ────────────────────────────────
echo ""
echo "▶ Writing time-series records..."
NOW=$(date +%s%3N)
awslocal timestream-write write-records \
  --database-name demo_metrics \
  --table-name cpu_usage \
  --records "[
    {\"Dimensions\":[{\"Name\":\"host\",\"Value\":\"web-01\"},{\"Name\":\"region\",\"Value\":\"us-east-1\"}],\"MeasureName\":\"cpu_utilization\",\"MeasureValue\":\"72.5\",\"MeasureValueType\":\"DOUBLE\",\"Time\":\"${NOW}\",\"TimeUnit\":\"MILLISECONDS\"},
    {\"Dimensions\":[{\"Name\":\"host\",\"Value\":\"web-02\"},{\"Name\":\"region\",\"Value\":\"us-east-1\"}],\"MeasureName\":\"cpu_utilization\",\"MeasureValue\":\"45.1\",\"MeasureValueType\":\"DOUBLE\",\"Time\":\"${NOW}\",\"TimeUnit\":\"MILLISECONDS\"}
  ]" > /dev/null
echo "  ✓ 2 records written (web-01: 72.5%, web-02: 45.1%)"

# ── Query the table ──────────────────────────────
echo ""
echo "▶ Querying CPU utilization data:"
awslocal timestream-query query \
  --query-string "SELECT host, measure_value::double AS cpu_pct, time FROM demo_metrics.cpu_usage ORDER BY time DESC LIMIT 10" \
  --query 'Rows[*].Data[*].ScalarValue' \
  --output table 2>/dev/null || \
  echo "  (Query API may require additional LocalStack tier — records written successfully)"

# ── Describe table ───────────────────────────────
echo ""
echo "▶ Describing table:"
awslocal timestream-write describe-table \
  --database-name demo_metrics \
  --table-name cpu_usage \
  --query 'Table.{Name:TableName,DB:DatabaseName,Status:TableStatus}' \
  --output table

echo ""
echo "✅  Timestream demo complete."

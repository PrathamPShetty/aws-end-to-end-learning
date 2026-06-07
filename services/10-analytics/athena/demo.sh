#!/bin/bash
# ═══════════════════════════════════════════════════════
#  Athena — Interactive SQL queries over S3 data
#  Creates a database, external table (CSV on S3), runs queries
# ═══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

BUCKET="athena-demo-bucket"
DB="sales_db"
RESULTS="s3://${BUCKET}/query-results/"

echo ""; echo "╔══════════════════════════════════════════╗"
echo "║   Athena Demo                            ║"; echo "╚══════════════════════════════════════════╝"

# ── S3 bucket + sample CSV ────────────────────────────
echo ""; echo "▶ Creating S3 bucket and uploading sample data..."
awslocal s3 mb "s3://${BUCKET}" > /dev/null 2>&1 || true
printf 'order_id,product,amount\n1,Widget,19.99\n2,Gadget,49.99\n3,Widget,19.99\n4,Doohickey,9.99\n' \
  | awslocal s3 cp - "s3://${BUCKET}/data/orders/orders.csv" > /dev/null
echo "  ✓ CSV uploaded to s3://${BUCKET}/data/orders/"

# ── Create Athena database ────────────────────────────
echo ""; echo "▶ Creating Athena database: ${DB}..."
QID=$(awslocal athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS ${DB}" \
  --result-configuration "OutputLocation=${RESULTS}" \
  --query 'QueryExecutionId' --output text)
echo "  ✓ Query id: ${QID}"

# ── Create external table ─────────────────────────────
echo ""; echo "▶ Creating external table pointing to S3..."
QID2=$(awslocal athena start-query-execution \
  --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS ${DB}.orders (order_id INT, product STRING, amount DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION 's3://${BUCKET}/data/orders/' TBLPROPERTIES ('skip.header.line.count'='1')" \
  --result-configuration "OutputLocation=${RESULTS}" \
  --query 'QueryExecutionId' --output text)
echo "  ✓ Table DDL query id: ${QID2}"

# ── Aggregation query ─────────────────────────────────
echo ""; echo "▶ Running aggregation: total sales by product..."
QID3=$(awslocal athena start-query-execution \
  --query-string "SELECT product, COUNT(*) AS orders, SUM(amount) AS total FROM ${DB}.orders GROUP BY product ORDER BY total DESC" \
  --result-configuration "OutputLocation=${RESULTS}" \
  --query 'QueryExecutionId' --output text)
echo "  ✓ Aggregation query id: ${QID3}"

# ── List executions ───────────────────────────────────
echo ""; echo "▶ Recent query executions:"
awslocal athena list-query-executions --query 'QueryExecutionIds' --output table

echo ""; echo "  ✅  Athena demo complete"; echo ""

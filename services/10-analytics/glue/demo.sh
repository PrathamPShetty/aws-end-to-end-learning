#!/bin/bash
# ═══════════════════════════════════════════════════════
#  Glue — Managed ETL: catalog database, table, and job
#  Creates a Glue database, registers a table, creates ETL job
# ═══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

BUCKET="glue-demo-bucket"
DB="glue_catalog_db"
JOB="glue-etl-job"
ROLE="arn:aws:iam::000000000000:role/glue-demo-role"

echo ""; echo "╔══════════════════════════════════════════╗"
echo "║   Glue Demo                              ║"; echo "╚══════════════════════════════════════════╝"

# ── S3 bucket for scripts and data ───────────────────
echo ""; echo "▶ Creating S3 bucket and uploading sample CSV..."
awslocal s3 mb "s3://${BUCKET}" > /dev/null 2>&1 || true
printf 'id,name,score\n1,Alice,95\n2,Bob,87\n3,Carol,92\n' \
  | awslocal s3 cp - "s3://${BUCKET}/input/scores.csv" > /dev/null
echo "  ✓ Bucket and sample data ready"

# ── Create Glue catalog database ─────────────────────
echo ""; echo "▶ Creating Glue catalog database: ${DB}..."
awslocal glue create-database \
  --database-input "Name=${DB},Description=Demo catalog database" > /dev/null 2>&1 || true
echo "  ✓ Database: ${DB}"

# ── Register a catalog table ──────────────────────────
echo ""; echo "▶ Registering table: scores..."
awslocal glue create-table --database-name "${DB}" --table-input '{
  "Name":"scores",
  "StorageDescriptor":{
    "Columns":[{"Name":"id","Type":"int"},{"Name":"name","Type":"string"},{"Name":"score","Type":"int"}],
    "Location":"s3://'"${BUCKET}"'/input/",
    "InputFormat":"org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat":"org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "SerdeInfo":{"SerializationLibrary":"org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe","Parameters":{"field.delim":","}}
  },"TableType":"EXTERNAL_TABLE"}' > /dev/null 2>&1 || true
echo "  ✓ Table: scores"

# ── Create a Glue ETL job ─────────────────────────────
echo ""; echo "▶ Creating Glue ETL job: ${JOB}..."
awslocal glue create-job --name "${JOB}" --role "${ROLE}" \
  --command "Name=glueetl,ScriptLocation=s3://${BUCKET}/scripts/etl.py,PythonVersion=3" \
  --glue-version "3.0" > /dev/null 2>&1 || true
echo "  ✓ Job: ${JOB}"

# ── List databases and tables ─────────────────────────
echo ""; echo "▶ Catalog databases:"
awslocal glue get-databases --query 'DatabaseList[].{Name:Name,Description:Description}' --output table
echo ""; echo "▶ Tables in ${DB}:"
awslocal glue get-tables --database-name "${DB}" --query 'TableList[].{Name:Name,Type:TableType}' --output table

echo ""; echo "  ✅  Glue demo complete"; echo ""

#!/bin/bash
# ============================================================
# CloudWatch Logs Demo — Log Groups, Streams, and Querying
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

LOG_GROUP="/demo/app/logs"
LOG_STREAM="demo-stream-001"
FILTER_NAME="demo-error-filter"

echo "==> Creating log group: $LOG_GROUP..."
awslocal logs create-log-group --log-group-name "$LOG_GROUP" || true

echo "==> Creating log stream: $LOG_STREAM..."
awslocal logs create-log-stream \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" || true

echo "==> Putting log events..."
TIMESTAMP=$(date +%s%3N)
awslocal logs put-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --log-events \
    timestamp=$TIMESTAMP,message="INFO: Application started successfully" \
    timestamp=$((TIMESTAMP+1000)),message="ERROR: Failed to connect to database" \
    timestamp=$((TIMESTAMP+2000)),message="INFO: Retry successful, connected to database"

echo "==> Retrieving log events..."
awslocal logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --query 'events[*].{Time:timestamp,Message:message}' \
  --output table

echo "==> Creating metric filter for ERROR events..."
awslocal logs put-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name "$FILTER_NAME" \
  --filter-pattern "ERROR" \
  --metric-transformations \
    metricName=ErrorCount,metricNamespace=Demo/Logs,metricValue=1 || true

echo "==> Describing metric filters..."
awslocal logs describe-metric-filters \
  --log-group-name "$LOG_GROUP" \
  --query 'metricFilters[*].{Name:filterName,Pattern:filterPattern}' \
  --output table

echo "==> Listing log groups..."
awslocal logs describe-log-groups \
  --query 'logGroups[*].{Name:logGroupName,RetentionDays:retentionInDays}' \
  --output table

echo "==> CloudWatch Logs demo complete."

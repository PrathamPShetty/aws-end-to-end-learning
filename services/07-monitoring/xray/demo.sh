#!/bin/bash
# ============================================================
# X-Ray Demo — Trace Segments, Sampling Rules, and Retrieval
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

SAMPLING_RULE="demo-sampling-rule"

echo "==> Sending a batch of trace segments..."
TRACE_ID="1-$(printf '%08x' $(date +%s))-$(openssl rand -hex 12 2>/dev/null || echo 'abcdef123456abcdef123456')"
SEGMENT_ID=$(openssl rand -hex 8 2>/dev/null || echo "abcdef12")
START_TIME=$(date +%s)
END_TIME=$((START_TIME + 1))

awslocal xray put-trace-segments --trace-segment-documents "[
  {
    \"name\": \"demo-service\",
    \"id\": \"${SEGMENT_ID}\",
    \"trace_id\": \"${TRACE_ID}\",
    \"start_time\": ${START_TIME}.0,
    \"end_time\": ${END_TIME}.0,
    \"in_progress\": false,
    \"annotations\": {\"env\": \"demo\"},
    \"metadata\": {\"version\": \"1.0\"},
    \"http\": {\"response\": {\"status\": 200}}
  }
]"

echo "==> Retrieving trace summaries..."
awslocal xray get-trace-summaries \
  --start-time $(($(date +%s) - 300)) \
  --end-time $(date +%s) \
  --query 'TraceSummaries[*].{Id:Id,Duration:Duration,ResponseTime:ResponseTime}' \
  --output table || true

echo "==> Creating sampling rule: $SAMPLING_RULE..."
RULE="{\"RuleName\":\"${SAMPLING_RULE}\",\"ResourceARN\":\"*\",\"Priority\":1000,\"FixedRate\":0.05,\"ReservoirSize\":5,\"ServiceName\":\"demo-service\",\"ServiceType\":\"*\",\"Host\":\"*\",\"HTTPMethod\":\"*\",\"URLPath\":\"*\",\"Version\":1}"
awslocal xray create-sampling-rule --sampling-rule "$RULE" || true

echo "==> Listing sampling rules..."
awslocal xray get-sampling-rules \
  --query 'SamplingRuleRecords[*].SamplingRule.{Name:RuleName,Rate:FixedRate,Priority:Priority}' \
  --output table

echo "==> Getting service graph (last 5 minutes)..."
awslocal xray get-service-graph --start-time $(($(date +%s) - 300)) --end-time $(date +%s) \
  --query 'Services[*].{Name:Name,Type:Type,State:State}' --output table || true

echo "==> X-Ray demo complete."

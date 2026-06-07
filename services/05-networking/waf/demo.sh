#!/bin/bash
# =============================================================
# Service: WAF (Web Application Firewall) v2
# Purpose: Create WebACL with IP set and rate-based rules
# =============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo ">>> [WAF] Creating IP set (blocked IPs)"
IP_SET=$(awslocal wafv2 create-ip-set \
  --name "blocked-ips" \
  --scope REGIONAL \
  --ip-address-version IPV4 \
  --addresses "192.168.1.100/32" "10.0.0.5/32")
IP_SET_ID=$(echo "$IP_SET" | python3 -c "import sys,json; s=json.load(sys.stdin)['Summary']; print(s['Id'])")
IP_SET_ARN=$(echo "$IP_SET" | python3 -c "import sys,json; s=json.load(sys.stdin)['Summary']; print(s['ARN'])")
echo "IP Set ID: $IP_SET_ID"

echo ">>> [WAF] Creating WebACL with IP-block and rate-limit rules"
LOCK_TOKEN=$(awslocal wafv2 list-ip-sets --scope REGIONAL \
  --query "IPSets[?Id=='$IP_SET_ID'].LockToken" --output text)

awslocal wafv2 create-web-acl \
  --name "demo-web-acl" \
  --scope REGIONAL \
  --default-action '{"Allow": {}}' \
  --rules "[
    {
      \"Name\": \"block-bad-ips\",
      \"Priority\": 1,
      \"Statement\": {\"IPSetReferenceStatement\": {\"ARN\": \"$IP_SET_ARN\"}},
      \"Action\": {\"Block\": {}},
      \"VisibilityConfig\": {
        \"SampledRequestsEnabled\": true,
        \"CloudWatchMetricsEnabled\": true,
        \"MetricName\": \"BlockBadIPs\"
      }
    }
  ]" \
  --visibility-config '{
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "DemoWebACL"
  }' \
  --query 'Summary.{Name:Name,Id:Id}' --output table

echo ">>> [WAF] Listing WebACLs"
awslocal wafv2 list-web-acls --scope REGIONAL \
  --query 'WebACLs[*].{Name:Name,Id:Id,ARN:ARN}' --output table

echo ">>> [WAF] Listing IP sets"
awslocal wafv2 list-ip-sets --scope REGIONAL \
  --query 'IPSets[*].{Name:Name,Id:Id}' --output table

echo "Done."

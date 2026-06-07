#!/bin/bash
# =============================================================
# Service: Route 53
# Purpose: DNS management — hosted zones, record sets, health
# =============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo ">>> [Route53] Creating hosted zone for example-demo.local"
ZONE=$(awslocal route53 create-hosted-zone \
  --name "example-demo.local" \
  --caller-reference "ref-$(date +%s)" \
  --query 'HostedZone.Id' --output text)
echo "Hosted Zone ID: $ZONE"

echo ">>> [Route53] Creating A record: app.example-demo.local -> 10.0.0.1"
awslocal route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE" \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.example-demo.local",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "10.0.0.1"}]
      }
    }]
  }'

echo ">>> [Route53] Creating CNAME record: www.example-demo.local -> app.example-demo.local"
awslocal route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE" \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.example-demo.local",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [{"Value": "app.example-demo.local"}]
      }
    }]
  }'

echo ">>> [Route53] Listing all record sets in zone"
awslocal route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE" \
  --output table

echo ">>> [Route53] Listing all hosted zones"
awslocal route53 list-hosted-zones --output table

echo "Done."

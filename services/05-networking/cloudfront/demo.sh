#!/bin/bash
# =============================================================
# Service: CloudFront
# Purpose: CDN distribution backed by S3 origin
# =============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BUCKET="cf-origin-demo-bucket"

echo ">>> [CloudFront] Creating S3 origin bucket: $BUCKET"
awslocal s3 mb "s3://$BUCKET" || true
awslocal s3 cp /dev/stdin "s3://$BUCKET/index.html" \
  --content-type "text/html" <<< "<html><body>Hello from CloudFront demo</body></html>"

echo ">>> [CloudFront] Creating CloudFront distribution"
DIST=$(awslocal cloudfront create-distribution \
  --distribution-config "{
    \"CallerReference\": \"ref-$(date +%s)\",
    \"Origins\": {
      \"Quantity\": 1,
      \"Items\": [{
        \"Id\": \"s3-origin\",
        \"DomainName\": \"${BUCKET}.s3.amazonaws.com\",
        \"S3OriginConfig\": {\"OriginAccessIdentity\": \"\"}
      }]
    },
    \"DefaultCacheBehavior\": {
      \"TargetOriginId\": \"s3-origin\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"ForwardedValues\": {
        \"QueryString\": false,
        \"Cookies\": {\"Forward\": \"none\"}
      },
      \"MinTTL\": 0
    },
    \"Comment\": \"Demo distribution\",
    \"Enabled\": true
  }")

DIST_ID=$(echo "$DIST" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])")
DOMAIN=$(echo "$DIST" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['DomainName'])")
echo "Distribution ID: $DIST_ID"
echo "Domain: $DOMAIN"

echo ">>> [CloudFront] Listing distributions"
awslocal cloudfront list-distributions \
  --query 'DistributionList.Items[*].{ID:Id,Domain:DomainName,Status:Status}' \
  --output table

echo ">>> [CloudFront] Getting distribution config"
awslocal cloudfront get-distribution --id "$DIST_ID" \
  --query 'Distribution.{Id:Id,Status:Status,DomainName:DomainName}' \
  --output table

echo "Done."

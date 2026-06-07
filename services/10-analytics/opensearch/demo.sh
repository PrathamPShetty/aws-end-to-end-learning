#!/bin/bash
# ═══════════════════════════════════════════════════════
#  OpenSearch — Managed search & analytics engine
#  Creates a domain, indexes documents, runs a query
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
DOMAIN="opensearch-demo"
ENDPOINT="http://localhost:4566"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   OpenSearch Demo                        ║"
echo "╚══════════════════════════════════════════╝"

# ── Create OpenSearch domain ──────────────────────────
echo ""
echo "▶ Creating OpenSearch domain: ${DOMAIN}..."
$AWS opensearch create-domain \
  --domain-name "${DOMAIN}" \
  --engine-version "OpenSearch_2.5" \
  --cluster-config "InstanceType=t3.small.search,InstanceCount=1" \
  --ebs-options "EBSEnabled=true,VolumeType=gp2,VolumeSize=10" \
  > /dev/null 2>&1 || true
echo "  ✓ Domain: ${DOMAIN}"

# ── Describe domain ───────────────────────────────────
echo ""
echo "▶ Domain details:"
$AWS opensearch describe-domain \
  --domain-name "${DOMAIN}" \
  --query 'DomainStatus.{Domain:DomainName,Engine:EngineVersion,Created:Created}' \
  --output table

# ── Index documents via REST (curl to LocalStack) ─────
echo ""
echo "▶ Indexing sample documents into OpenSearch..."
DOMAIN_EP=$($AWS opensearch describe-domain \
  --domain-name "${DOMAIN}" \
  --query 'DomainStatus.Endpoint' --output text 2>/dev/null || echo "localhost:4566/opensearch/us-east-1/${DOMAIN}")

BASE_URL="http://${DOMAIN_EP}"

curl -s -X PUT "${BASE_URL}/products/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Widget","category":"hardware","price":19.99}' | grep -o '"result":"[^"]*"' || true

curl -s -X PUT "${BASE_URL}/products/_doc/2" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Gadget","category":"electronics","price":49.99}' | grep -o '"result":"[^"]*"' || true
echo "  ✓ 2 documents indexed"

# ── Search documents ──────────────────────────────────
echo ""
echo "▶ Searching for 'electronics' category..."
curl -s -X GET "${BASE_URL}/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"category":"electronics"}}}' \
  | python3 -c "import sys,json; hits=json.load(sys.stdin).get('hits',{}); [print('  -',h['_source']) for h in hits.get('hits',[])]" || true

# ── List domains ──────────────────────────────────────
echo ""
echo "▶ All OpenSearch domains:"
$AWS opensearch list-domain-names \
  --query 'DomainNames[].DomainName' \
  --output table

echo ""
echo "  ✅  OpenSearch demo complete"
echo ""

#!/bin/bash
# ═══════════════════════════════════════════════════════
#  OpenSearch — Managed search & analytics engine
#  Creates a domain, indexes documents via REST, searches
# ═══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

DOMAIN="opensearch-demo"

echo ""; echo "╔══════════════════════════════════════════╗"
echo "║   OpenSearch Demo                        ║"; echo "╚══════════════════════════════════════════╝"

# ── Create OpenSearch domain ──────────────────────────
echo ""; echo "▶ Creating OpenSearch domain: ${DOMAIN}..."
awslocal opensearch create-domain \
  --domain-name "${DOMAIN}" \
  --engine-version "OpenSearch_2.5" \
  --cluster-config "InstanceType=t3.small.search,InstanceCount=1" \
  --ebs-options "EBSEnabled=true,VolumeType=gp2,VolumeSize=10" \
  > /dev/null 2>&1 || true
echo "  ✓ Domain: ${DOMAIN}"

# ── Describe domain ───────────────────────────────────
echo ""; echo "▶ Domain details:"
awslocal opensearch describe-domain --domain-name "${DOMAIN}" \
  --query 'DomainStatus.{Domain:DomainName,Engine:EngineVersion,Created:Created}' --output table

# ── Derive REST endpoint ──────────────────────────────
RAW_EP=$(awslocal opensearch describe-domain --domain-name "${DOMAIN}" \
  --query 'DomainStatus.Endpoint' --output text 2>/dev/null || true)
BASE_URL="http://${RAW_EP:-localhost:4566/opensearch/us-east-1/${DOMAIN}}"

# ── Index documents ───────────────────────────────────
echo ""; echo "▶ Indexing sample documents..."
curl -sf -X PUT "${BASE_URL}/products/_doc/1" -H 'Content-Type: application/json' \
  -d '{"name":"Widget","category":"hardware","price":19.99}' | python3 -c "import sys,json; r=json.load(sys.stdin); print('  doc 1:',r.get('result'))" || true
curl -sf -X PUT "${BASE_URL}/products/_doc/2" -H 'Content-Type: application/json' \
  -d '{"name":"Gadget","category":"electronics","price":49.99}' | python3 -c "import sys,json; r=json.load(sys.stdin); print('  doc 2:',r.get('result'))" || true

# ── Search documents ──────────────────────────────────
echo ""; echo "▶ Searching for 'electronics'..."
curl -sf -X GET "${BASE_URL}/products/_search" -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"category":"electronics"}}}' \
  | python3 -c "import sys,json; hits=json.load(sys.stdin).get('hits',{}); [print('  -',h['_source']) for h in hits.get('hits',[])]" || true

# ── List domains ──────────────────────────────────────
echo ""; echo "▶ All OpenSearch domains:"
awslocal opensearch list-domain-names --query 'DomainNames[].DomainName' --output table

echo ""; echo "  ✅  OpenSearch demo complete"; echo ""

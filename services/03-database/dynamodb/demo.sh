#!/bin/bash
# ═══════════════════════════════════════════════════════
#  DynamoDB — NoSQL key-value & document database demo
#  Creates a Products table, writes items, queries & scans
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   DynamoDB Demo                          ║"
echo "╚══════════════════════════════════════════╝"

# ── Create table ────────────────────────────────
echo ""
echo "▶ Creating Products table..."
awslocal dynamodb create-table \
  --table-name Products \
  --attribute-definitions \
    AttributeName=productId,AttributeType=S \
    AttributeName=category,AttributeType=S \
  --key-schema \
    AttributeName=productId,KeyType=HASH \
    AttributeName=category,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  > /dev/null 2>&1 || true
echo "  ✓ Table: Products"

# ── Write items ──────────────────────────────────
echo ""
echo "▶ Inserting items..."
awslocal dynamodb put-item --table-name Products \
  --item '{"productId":{"S":"p1"},"category":{"S":"electronics"},"name":{"S":"Laptop"},"price":{"N":"999"}}'
awslocal dynamodb put-item --table-name Products \
  --item '{"productId":{"S":"p2"},"category":{"S":"electronics"},"name":{"S":"Phone"},"price":{"N":"499"}}'
awslocal dynamodb put-item --table-name Products \
  --item '{"productId":{"S":"p3"},"category":{"S":"books"},"name":{"S":"AWS Cookbook"},"price":{"N":"49"}}'
echo "  ✓ 3 items inserted"

# ── Get a single item ────────────────────────────
echo ""
echo "▶ GetItem — fetch Laptop (p1):"
awslocal dynamodb get-item \
  --table-name Products \
  --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}' \
  --query 'Item.{id:productId.S,name:name.S,price:price.N}' \
  --output table

# ── Update an item ───────────────────────────────
echo ""
echo "▶ UpdateItem — apply 10% discount to Laptop..."
awslocal dynamodb update-item \
  --table-name Products \
  --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}' \
  --update-expression "SET price = :p" \
  --expression-attribute-values '{":p":{"N":"899"}}' \
  --return-values UPDATED_NEW \
  --query 'Attributes.price.N' --output text

# ── Scan table ───────────────────────────────────
echo ""
echo "▶ Scan all products:"
awslocal dynamodb scan \
  --table-name Products \
  --query 'Items[*].{id:productId.S,name:name.S,price:price.N}' \
  --output table

echo ""
echo "✅  DynamoDB demo complete."

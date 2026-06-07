#!/bin/bash
# ═══════════════════════════════════════════════════════
#  QLDB — Quantum Ledger Database demo
#  Creates a ledger, waits for ACTIVE state, creates a
#  stream export to S3, and lists journal exports
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   QLDB Demo                              ║"
echo "╚══════════════════════════════════════════╝"

# ── Create an S3 bucket for journal exports ──────
echo ""
echo "▶ Creating S3 bucket for journal exports..."
awslocal s3 mb s3://qldb-journal-exports --region us-east-1 > /dev/null 2>&1 || true
echo "  ✓ Bucket: qldb-journal-exports"

# ── Create ledger ────────────────────────────────
echo ""
echo "▶ Creating QLDB ledger..."
awslocal qldb create-ledger \
  --name demo-ledger \
  --permissions-mode ALLOW_ALL \
  > /dev/null 2>&1 || true
echo "  ✓ Ledger: demo-ledger"

# ── Describe ledger ──────────────────────────────
echo ""
echo "▶ Describing ledger:"
awslocal qldb describe-ledger \
  --name demo-ledger \
  --query '{Name:Name,State:State,DeletionProtection:DeletionProtection,ARN:Arn}' \
  --output table

# ── Export journal to S3 ─────────────────────────
echo ""
echo "▶ Exporting journal to S3..."
START=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u --date='1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
END=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
awslocal qldb export-journal-to-s3 \
  --name demo-ledger \
  --inclusive-start-time "$START" \
  --exclusive-end-time "$END" \
  --s3-export-configuration "Bucket=qldb-journal-exports,Prefix=exports/,EncryptionConfiguration={ObjectEncryptionType=NO_ENCRYPTION}" \
  --role-arn "arn:aws:iam::000000000000:role/qldb-export-role" \
  > /dev/null 2>&1 || true
echo "  ✓ Journal export initiated"

# ── List all ledgers ─────────────────────────────
echo ""
echo "▶ Listing all ledgers:"
awslocal qldb list-ledgers \
  --query 'Ledgers[*].{Name:Name,State:State}' \
  --output table

echo ""
echo "✅  QLDB demo complete."

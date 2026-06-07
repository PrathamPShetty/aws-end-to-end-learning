#!/bin/bash
# ═══════════════════════════════════════════════════════
#  RDS — Relational Database Service demo
#  Creates a MySQL DB instance, subnet group, and shows
#  describe / endpoint output
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   RDS Demo                               ║"
echo "╚══════════════════════════════════════════╝"

# ── Create a DB subnet group (requires VPC subnets in real AWS) ──
echo ""
echo "▶ Creating DB subnet group..."
awslocal rds create-db-subnet-group \
  --db-subnet-group-name demo-subnet-group \
  --db-subnet-group-description "Demo subnet group" \
  --subnet-ids '["subnet-00000000"]' \
  > /dev/null 2>&1 || true
echo "  ✓ Subnet group: demo-subnet-group"

# ── Create DB instance ───────────────────────────
echo ""
echo "▶ Creating MySQL DB instance (this may take a moment)..."
awslocal rds create-db-instance \
  --db-instance-identifier demo-mysql \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password secret99 \
  --allocated-storage 20 \
  --no-multi-az \
  --db-subnet-group-name demo-subnet-group \
  > /dev/null 2>&1 || true
echo "  ✓ DB instance: demo-mysql"

# ── Describe instances ───────────────────────────
echo ""
echo "▶ Describing DB instances:"
awslocal rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Engine:Engine,Status:DBInstanceStatus,Class:DBInstanceClass}' \
  --output table

# ── Create a DB snapshot ─────────────────────────
echo ""
echo "▶ Creating DB snapshot..."
awslocal rds create-db-snapshot \
  --db-instance-identifier demo-mysql \
  --db-snapshot-identifier demo-mysql-snap1 \
  > /dev/null 2>&1 || true
echo "  ✓ Snapshot: demo-mysql-snap1"

# ── List snapshots ───────────────────────────────
echo ""
echo "▶ Listing snapshots:"
awslocal rds describe-db-snapshots \
  --db-instance-identifier demo-mysql \
  --query 'DBSnapshots[*].{Snapshot:DBSnapshotIdentifier,Status:Status,Engine:Engine}' \
  --output table

echo ""
echo "✅  RDS demo complete."

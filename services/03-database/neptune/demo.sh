#!/bin/bash
# ═══════════════════════════════════════════════════════
#  Neptune — Managed graph database demo
#  Creates a Neptune cluster + instance, subnet group,
#  and inspects the graph database endpoint
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Neptune Demo                           ║"
echo "╚══════════════════════════════════════════╝"

# ── Create subnet group ──────────────────────────
echo ""
echo "▶ Creating Neptune subnet group..."
awslocal neptune create-db-subnet-group \
  --db-subnet-group-name demo-neptune-subnets \
  --db-subnet-group-description "Demo Neptune subnet group" \
  --subnet-ids '["subnet-00000000"]' \
  > /dev/null 2>&1 || true
echo "  ✓ Subnet group: demo-neptune-subnets"

# ── Create Neptune cluster ───────────────────────
echo ""
echo "▶ Creating Neptune DB cluster..."
awslocal neptune create-db-cluster \
  --db-cluster-identifier demo-neptune-cluster \
  --engine neptune \
  --db-subnet-group-name demo-neptune-subnets \
  > /dev/null 2>&1 || true
echo "  ✓ Cluster: demo-neptune-cluster"

# ── Create Neptune instance ──────────────────────
echo ""
echo "▶ Creating Neptune DB instance..."
awslocal neptune create-db-instance \
  --db-instance-identifier demo-neptune-instance \
  --db-instance-class db.r5.large \
  --engine neptune \
  --db-cluster-identifier demo-neptune-cluster \
  > /dev/null 2>&1 || true
echo "  ✓ Instance: demo-neptune-instance"

# ── Describe cluster ─────────────────────────────
echo ""
echo "▶ Describing Neptune clusters:"
awslocal neptune describe-db-clusters \
  --db-cluster-identifier demo-neptune-cluster \
  --query 'DBClusters[*].{ID:DBClusterIdentifier,Engine:Engine,Status:Status,Endpoint:Endpoint}' \
  --output table

# ── Describe instances ───────────────────────────
echo ""
echo "▶ Describing Neptune instances:"
awslocal neptune describe-db-instances \
  --db-instance-identifier demo-neptune-instance \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Status:DBInstanceStatus}' \
  --output table

echo ""
echo "✅  Neptune demo complete."

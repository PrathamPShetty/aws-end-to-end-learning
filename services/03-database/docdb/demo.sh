#!/bin/bash
# ═══════════════════════════════════════════════════════
#  DocumentDB — Managed MongoDB-compatible database demo
#  Creates a DocDB cluster + instance, subnet group,
#  then describes the cluster and takes a snapshot
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   DocumentDB Demo                        ║"
echo "╚══════════════════════════════════════════╝"

# ── Create subnet group ──────────────────────────
echo ""
echo "▶ Creating DocumentDB subnet group..."
awslocal docdb create-db-subnet-group \
  --db-subnet-group-name demo-docdb-subnets \
  --db-subnet-group-description "Demo DocumentDB subnet group" \
  --subnet-ids '["subnet-00000000"]' \
  > /dev/null 2>&1 || true
echo "  ✓ Subnet group: demo-docdb-subnets"

# ── Create cluster parameter group ──────────────
echo ""
echo "▶ Creating cluster parameter group..."
awslocal docdb create-db-cluster-parameter-group \
  --db-cluster-parameter-group-name demo-docdb-pg \
  --db-parameter-group-family docdb5.0 \
  --description "Demo DocDB parameter group" \
  > /dev/null 2>&1 || true
echo "  ✓ Parameter group: demo-docdb-pg"

# ── Create DocumentDB cluster ────────────────────
echo ""
echo "▶ Creating DocumentDB cluster..."
awslocal docdb create-db-cluster \
  --db-cluster-identifier demo-docdb-cluster \
  --engine docdb \
  --master-username docadmin \
  --master-user-password Secret123 \
  --db-subnet-group-name demo-docdb-subnets \
  --db-cluster-parameter-group-name demo-docdb-pg \
  > /dev/null 2>&1 || true
echo "  ✓ Cluster: demo-docdb-cluster"

# ── Create DocumentDB instance ───────────────────
echo ""
echo "▶ Creating DocumentDB instance..."
awslocal docdb create-db-instance \
  --db-instance-identifier demo-docdb-instance \
  --db-instance-class db.r5.large \
  --engine docdb \
  --db-cluster-identifier demo-docdb-cluster \
  > /dev/null 2>&1 || true
echo "  ✓ Instance: demo-docdb-instance"

# ── Describe cluster ─────────────────────────────
echo ""
echo "▶ Describing DocumentDB cluster:"
awslocal docdb describe-db-clusters \
  --db-cluster-identifier demo-docdb-cluster \
  --query 'DBClusters[*].{ID:DBClusterIdentifier,Engine:Engine,Status:Status,Endpoint:Endpoint}' \
  --output table

# ── Create cluster snapshot ──────────────────────
echo ""
echo "▶ Creating cluster snapshot..."
awslocal docdb create-db-cluster-snapshot \
  --db-cluster-identifier demo-docdb-cluster \
  --db-cluster-snapshot-identifier demo-docdb-snap1 \
  > /dev/null 2>&1 || true
echo "  ✓ Snapshot: demo-docdb-snap1"
awslocal docdb describe-db-cluster-snapshots \
  --db-cluster-identifier demo-docdb-cluster \
  --query 'DBClusterSnapshots[*].{Snapshot:DBClusterSnapshotIdentifier,Status:Status}' \
  --output table

echo ""
echo "✅  DocumentDB demo complete."

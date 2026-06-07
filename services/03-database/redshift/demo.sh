#!/bin/bash
# ═══════════════════════════════════════════════════════
#  Redshift — Cloud data warehouse demo
#  Creates a cluster, subnet group, and runs a describe;
#  also demonstrates cluster parameter group creation
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Redshift Demo                          ║"
echo "╚══════════════════════════════════════════╝"

# ── Create a cluster subnet group ───────────────
echo ""
echo "▶ Creating cluster subnet group..."
awslocal redshift create-cluster-subnet-group \
  --cluster-subnet-group-name demo-subnet-group \
  --description "Demo Redshift subnet group" \
  --subnet-ids '["subnet-00000000"]' \
  > /dev/null 2>&1 || true
echo "  ✓ Subnet group: demo-subnet-group"

# ── Create a cluster parameter group ────────────
echo ""
echo "▶ Creating cluster parameter group..."
awslocal redshift create-cluster-parameter-group \
  --parameter-group-name demo-pg \
  --parameter-group-family redshift-1.0 \
  --description "Demo parameter group" \
  > /dev/null 2>&1 || true
echo "  ✓ Parameter group: demo-pg"

# ── Create a Redshift cluster ────────────────────
echo ""
echo "▶ Creating Redshift cluster..."
awslocal redshift create-cluster \
  --cluster-identifier demo-cluster \
  --node-type dc2.large \
  --master-username awsuser \
  --master-user-password Test1234 \
  --cluster-type single-node \
  --cluster-subnet-group-name demo-subnet-group \
  --cluster-parameter-group-name demo-pg \
  --db-name analytics \
  > /dev/null 2>&1 || true
echo "  ✓ Cluster: demo-cluster"

# ── Describe cluster ─────────────────────────────
echo ""
echo "▶ Describing clusters:"
awslocal redshift describe-clusters \
  --query 'Clusters[*].{ID:ClusterIdentifier,Status:ClusterStatus,NodeType:NodeType,DB:DBName}' \
  --output table

# ── Create a snapshot ───────────────────────────
echo ""
echo "▶ Creating manual cluster snapshot..."
awslocal redshift create-cluster-snapshot \
  --cluster-identifier demo-cluster \
  --snapshot-identifier demo-cluster-snap1 \
  > /dev/null 2>&1 || true
echo "  ✓ Snapshot: demo-cluster-snap1"

echo ""
echo "▶ Listing snapshots:"
awslocal redshift describe-cluster-snapshots \
  --cluster-identifier demo-cluster \
  --query 'Snapshots[*].{Snapshot:SnapshotIdentifier,Status:Status,Type:SnapshotType}' \
  --output table

echo ""
echo "✅  Redshift demo complete."

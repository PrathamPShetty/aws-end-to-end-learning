#!/bin/bash
# ═══════════════════════════════════════════════════════
#  ElastiCache — Managed in-memory cache demo
#  Creates a Redis cache cluster and a parameter group,
#  then inspects cluster details
# ═══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ElastiCache Demo                       ║"
echo "╚══════════════════════════════════════════╝"

# ── Create a custom parameter group ─────────────
echo ""
echo "▶ Creating parameter group..."
awslocal elasticache create-cache-parameter-group \
  --cache-parameter-group-name demo-redis-params \
  --cache-parameter-group-family redis7 \
  --description "Demo Redis parameter group" \
  > /dev/null 2>&1 || true
echo "  ✓ Parameter group: demo-redis-params"

# ── Create a subnet group ────────────────────────
echo ""
echo "▶ Creating subnet group..."
awslocal elasticache create-cache-subnet-group \
  --cache-subnet-group-name demo-subnet-group \
  --cache-subnet-group-description "Demo subnet group" \
  --subnet-ids '["subnet-00000000"]' \
  > /dev/null 2>&1 || true
echo "  ✓ Subnet group: demo-subnet-group"

# ── Create Redis cluster ─────────────────────────
echo ""
echo "▶ Creating Redis cache cluster..."
awslocal elasticache create-cache-cluster \
  --cache-cluster-id demo-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --cache-parameter-group-name demo-redis-params \
  --cache-subnet-group-name demo-subnet-group \
  > /dev/null 2>&1 || true
echo "  ✓ Cluster: demo-redis"

# ── Describe cluster ─────────────────────────────
echo ""
echo "▶ Describing cache clusters:"
awslocal elasticache describe-cache-clusters \
  --cache-cluster-id demo-redis \
  --query 'CacheClusters[*].{ID:CacheClusterId,Engine:Engine,Status:CacheClusterStatus,NodeType:CacheNodeType}' \
  --output table

# ── List parameter groups ────────────────────────
echo ""
echo "▶ Listing parameter groups:"
awslocal elasticache describe-cache-parameter-groups \
  --query 'CacheParameterGroups[*].{Name:CacheParameterGroupName,Family:CacheParameterGroupFamily}' \
  --output table

echo ""
echo "✅  ElastiCache demo complete."

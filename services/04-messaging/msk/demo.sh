#!/bin/bash
# ============================================================
# Amazon MSK (Managed Streaming for Kafka) Demo
# Purpose: Create MSK cluster, describe it, list brokers
# Note: LocalStack supports MSK cluster management APIs
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

CLUSTER_NAME="demo-kafka-cluster"

echo "==> Creating MSK cluster..."
CLUSTER_ARN=$(awslocal kafka create-cluster \
  --cluster-name "$CLUSTER_NAME" \
  --kafka-version "2.8.1" \
  --number-of-broker-nodes 2 \
  --broker-node-group-info "{
    \"InstanceType\": \"kafka.m5.large\",
    \"ClientSubnets\": [\"subnet-00000000\", \"subnet-11111111\"],
    \"StorageInfo\": {\"EbsStorageInfo\": {\"VolumeSize\": 20}}
  }" \
  --output text --query 'ClusterArn') || true
echo "Cluster ARN: $CLUSTER_ARN"

echo "==> Waiting for cluster to become ACTIVE..."
for i in $(seq 1 20); do
  STATE=$(awslocal kafka describe-cluster --cluster-arn "$CLUSTER_ARN" \
    --output text --query 'ClusterInfo.State' 2>/dev/null || echo "CREATING")
  echo "  State: $STATE"
  [ "$STATE" = "ACTIVE" ] && break
  sleep 2
done

echo "==> Cluster details:"
awslocal kafka describe-cluster --cluster-arn "$CLUSTER_ARN" \
  --output table \
  --query 'ClusterInfo.{Name:ClusterName,State:State,Version:CurrentBrokerSoftwareInfo.KafkaVersion,Brokers:NumberOfBrokerNodes}'

echo "==> Getting bootstrap brokers..."
awslocal kafka get-bootstrap-brokers --cluster-arn "$CLUSTER_ARN" || true

echo "==> Creating MSK configuration..."
awslocal kafka create-configuration \
  --name "demo-kafka-config" \
  --kafka-versions '["2.8.1"]' \
  --server-properties "$(echo 'auto.create.topics.enable=true
default.replication.factor=2
min.insync.replicas=1
num.partitions=3' | base64)" || true

echo "==> Listing MSK clusters:"
awslocal kafka list-clusters --output table \
  --query 'ClusterInfoList[*].{Name:ClusterName,ARN:ClusterArn,State:State}'

echo "==> MSK demo complete."

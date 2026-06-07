#!/bin/bash
# ============================================================
# Amazon MQ Demo
# Purpose: Create ActiveMQ broker, show connection details, list brokers
# Note: LocalStack supports MQ broker creation (ACTIVEMQ engine)
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

BROKER_NAME="demo-activemq-broker"
MQ_USER="demouser"
MQ_PASS="DemoPass123!"

echo "==> Creating ActiveMQ broker (single-instance)..."
BROKER_ID=$(awslocal mq create-broker \
  --broker-name "$BROKER_NAME" \
  --engine-type ACTIVEMQ \
  --engine-version "5.15.14" \
  --host-instance-type "mq.m5.large" \
  --deployment-mode SINGLE_INSTANCE \
  --publicly-accessible \
  --users "[{\"Username\":\"$MQ_USER\",\"Password\":\"$MQ_PASS\",\"Groups\":[\"admin\"]}]" \
  --output text --query 'BrokerId') || true
echo "Broker ID: $BROKER_ID"

echo "==> Waiting for broker to reach RUNNING state..."
for i in $(seq 1 20); do
  STATUS=$(awslocal mq describe-broker --broker-id "$BROKER_ID" \
    --output text --query 'BrokerState' 2>/dev/null || echo "PENDING")
  echo "  State: $STATUS"
  [ "$STATUS" = "RUNNING" ] && break
  sleep 2
done

echo "==> Broker details:"
awslocal mq describe-broker --broker-id "$BROKER_ID" \
  --output table \
  --query '{Name:BrokerName,State:BrokerState,Engine:EngineType,Version:EngineVersion}'

echo "==> Broker endpoints:"
awslocal mq describe-broker --broker-id "$BROKER_ID" \
  --output text --query 'BrokerInstances[*].Endpoints[]'

echo "==> Creating a broker configuration..."
awslocal mq create-configuration \
  --name "demo-activemq-config" \
  --engine-type ACTIVEMQ \
  --engine-version "5.15.14" || true

echo "==> Listing all MQ brokers:"
awslocal mq list-brokers --output table \
  --query 'BrokerSummaries[*].{Name:BrokerName,ID:BrokerId,State:BrokerState}'

echo "==> MQ demo complete."

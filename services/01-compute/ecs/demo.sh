#!/bin/bash
# ══════════════════════════════════════════════════════
#  ECS Demo — Cluster, task definition, service, list
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
ACCOUNT="000000000000"
CLUSTER="demo-cluster"
TASK_DEF="demo-task"
SERVICE="demo-service"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   ECS Demo                           ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── IAM role for ECS task execution ───────────────────
echo "▶ Creating ECS task execution role..."
$AWS iam create-role \
  --role-name ecs-task-exec-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
echo "  ✓ Role ready"

# ── ECS Cluster ────────────────────────────────────────
echo "▶ Creating ECS cluster: $CLUSTER..."
$AWS ecs create-cluster \
  --cluster-name "$CLUSTER" \
  --query 'cluster.{Name:clusterName,Status:status}' \
  --output table
echo "  ✓ Cluster created"

# ── Task Definition ────────────────────────────────────
echo "▶ Registering task definition: $TASK_DEF..."
$AWS ecs register-task-definition \
  --family "$TASK_DEF" \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu "256" --memory "512" \
  --execution-role-arn "arn:aws:iam::${ACCOUNT}:role/ecs-task-exec-role" \
  --container-definitions '[{
    "name":"web",
    "image":"nginx:alpine",
    "portMappings":[{"containerPort":80,"protocol":"tcp"}],
    "essential":true,
    "logConfiguration":{"logDriver":"awslogs","options":{"awslogs-group":"/ecs/demo","awslogs-region":"us-east-1","awslogs-stream-prefix":"ecs"}}
  }]' \
  --query 'taskDefinition.{Family:family,Revision:revision,Status:status}' \
  --output table > /dev/null
echo "  ✓ Task definition registered"

# ── Service ────────────────────────────────────────────
echo "▶ Creating ECS service: $SERVICE..."
$AWS ecs create-service \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --task-definition "$TASK_DEF" \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration 'awsvpcConfiguration={subnets=["subnet-00000000"],securityGroups=["sg-00000000"],assignPublicIp=DISABLED}' \
  --query 'service.{Name:serviceName,Status:status,Desired:desiredCount}' \
  --output table > /dev/null
echo "  ✓ Service created"

# ── List clusters and services ─────────────────────────
echo "▶ Clusters:"
$AWS ecs list-clusters --query 'clusterArns' --output table

echo "▶ Services in $CLUSTER:"
$AWS ecs list-services --cluster "$CLUSTER" \
  --query 'serviceArns' --output table

# ── Update service desired count ───────────────────────
echo "▶ Scaling service to 2 tasks..."
$AWS ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --desired-count 2 \
  --query 'service.{Name:serviceName,Desired:desiredCount}' \
  --output table > /dev/null
echo "  ✓ Desired count updated to 2"

echo ""
echo "  ✅  ECS demo complete"
echo ""

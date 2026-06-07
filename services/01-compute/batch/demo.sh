#!/bin/bash
# ══════════════════════════════════════════════════════
#  Batch Demo — Compute env, job queue, job definition,
#               submit job, describe job status
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
ACCOUNT="000000000000"
CE="demo-compute-env"
QUEUE="demo-job-queue"
JOB_DEF="demo-job-def"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Batch Demo                         ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── IAM roles ─────────────────────────────────────────
echo "▶ Creating Batch IAM roles..."
$AWS iam create-role \
  --role-name batch-service-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"batch.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
$AWS iam create-role \
  --role-name batch-instance-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
echo "  ✓ Roles ready"

# ── Compute Environment ────────────────────────────────
echo "▶ Creating compute environment: $CE..."
$AWS batch create-compute-environment \
  --compute-environment-name "$CE" \
  --type MANAGED \
  --state ENABLED \
  --compute-resources "type=FARGATE,maxvCpus=4,subnets=[subnet-00000000],securityGroupIds=[sg-00000000]" \
  --service-role "arn:aws:iam::${ACCOUNT}:role/batch-service-role" \
  > /dev/null 2>&1 || true
echo "  ✓ Compute environment created"

# ── Job Queue ──────────────────────────────────────────
echo "▶ Creating job queue: $QUEUE..."
$AWS batch create-job-queue \
  --job-queue-name "$QUEUE" \
  --state ENABLED \
  --priority 100 \
  --compute-environment-order "order=1,computeEnvironment=$CE" \
  > /dev/null 2>&1 || true
echo "  ✓ Job queue created"

# ── Job Definition ─────────────────────────────────────
echo "▶ Registering job definition: $JOB_DEF..."
$AWS batch register-job-definition \
  --job-definition-name "$JOB_DEF" \
  --type container \
  --platform-capabilities FARGATE \
  --container-properties '{
    "image":"public.ecr.aws/amazonlinux/amazonlinux:2",
    "command":["echo","Hello from AWS Batch"],
    "resourceRequirements":[
      {"type":"VCPU","value":"0.25"},
      {"type":"MEMORY","value":"512"}
    ],
    "executionRoleArn":"arn:aws:iam::000000000000:role/batch-instance-role",
    "networkConfiguration":{"assignPublicIp":"DISABLED"},
    "fargatePlatformConfiguration":{"platformVersion":"LATEST"}
  }' \
  --query 'jobDefinitionName' --output text > /dev/null
echo "  ✓ Job definition registered"

# ── Submit Job ─────────────────────────────────────────
echo "▶ Submitting job..."
JOB_ID=$($AWS batch submit-job \
  --job-name "demo-run-$(date +%s)" \
  --job-queue "$QUEUE" \
  --job-definition "$JOB_DEF" \
  --query 'jobId' --output text)
echo "  ✓ Job submitted: $JOB_ID"

# ── Describe Job ───────────────────────────────────────
echo "▶ Job status:"
$AWS batch describe-jobs \
  --jobs "$JOB_ID" \
  --query 'jobs[].{Name:jobName,Status:status,Queue:jobQueue}' \
  --output table

# ── List Job Queues ────────────────────────────────────
echo "▶ All job queues:"
$AWS batch describe-job-queues \
  --query 'jobQueues[].{Name:jobQueueName,State:state,Priority:priority}' \
  --output table

echo ""
echo "  ✅  Batch demo complete"
echo ""

#!/bin/bash
# ═══════════════════════════════════════════════════════
#  EMR — Elastic MapReduce: cluster lifecycle + Spark step
#  Creates a cluster, adds a Spark step, lists step status
# ═══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

BUCKET="emr-demo-bucket"
CLUSTER_NAME="emr-demo-cluster"

echo ""; echo "╔══════════════════════════════════════════╗"
echo "║   EMR Demo                               ║"; echo "╚══════════════════════════════════════════╝"

# ── S3 bucket for logs ────────────────────────────────
echo ""; echo "▶ Creating S3 bucket for EMR logs..."
awslocal s3 mb "s3://${BUCKET}" > /dev/null 2>&1 || true
echo "  ✓ Bucket: ${BUCKET}"

# ── Create EMR cluster ────────────────────────────────
echo ""; echo "▶ Creating EMR cluster: ${CLUSTER_NAME}..."
CLUSTER_ID=$(awslocal emr create-cluster \
  --name "${CLUSTER_NAME}" \
  --release-label "emr-6.9.0" \
  --applications Name=Spark Name=Hadoop \
  --instance-type "m5.xlarge" \
  --instance-count 2 \
  --log-uri "s3://${BUCKET}/logs/" \
  --use-default-roles \
  --no-auto-terminate \
  --query 'ClusterId' --output text)
echo "  ✓ Cluster ID: ${CLUSTER_ID}"

# ── Describe cluster ──────────────────────────────────
echo ""; echo "▶ Cluster details:"
awslocal emr describe-cluster --cluster-id "${CLUSTER_ID}" \
  --query 'Cluster.{Id:Id,Name:Name,State:Status.State,Release:ReleaseLabel}' --output table

# ── Add a Spark step ──────────────────────────────────
echo ""; echo "▶ Adding Spark Pi step..."
STEP_ID=$(awslocal emr add-steps --cluster-id "${CLUSTER_ID}" \
  --steps '[{"Name":"SparkPi","ActionOnFailure":"CONTINUE","HadoopJarStep":{"Jar":"command-runner.jar","Args":["spark-submit","--class","org.apache.spark.examples.SparkPi","/usr/lib/spark/examples/jars/spark-examples.jar","10"]}}]' \
  --query 'StepIds[0]' --output text)
echo "  ✓ Step ID: ${STEP_ID}"

# ── List steps ────────────────────────────────────────
echo ""; echo "▶ Steps on cluster:"
awslocal emr list-steps --cluster-id "${CLUSTER_ID}" \
  --query 'Steps[].{Id:Id,Name:Name,State:Status.State}' --output table

echo ""; echo "  ✅  EMR demo complete"; echo ""

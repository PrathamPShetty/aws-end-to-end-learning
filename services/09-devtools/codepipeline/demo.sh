#!/bin/bash
# ══════════════════════════════════════════════════════
#  CodePipeline Demo — Create pipeline, get state, tags
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
ACCOUNT="000000000000"
PIPELINE="demo-pipeline-$$"
BUCKET="pipeline-artifacts-$$"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   CodePipeline Demo                  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── IAM role ──────────────────────────────────────────
echo "▶ Creating IAM role for CodePipeline..."
$AWS iam create-role \
  --role-name codepipeline-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codepipeline.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
echo "  ✓ Role ready"

# ── S3 artifact store ─────────────────────────────────
echo "▶ Creating S3 artifact store bucket..."
$AWS s3api create-bucket --bucket "$BUCKET" > /dev/null 2>&1 || true
echo "  ✓ Bucket ready: $BUCKET"

# ── Create pipeline ───────────────────────────────────
echo "▶ Creating pipeline: $PIPELINE..."
$AWS codepipeline create-pipeline \
  --pipeline "{
    \"name\": \"$PIPELINE\",
    \"roleArn\": \"arn:aws:iam::${ACCOUNT}:role/codepipeline-demo-role\",
    \"artifactStore\": {\"type\": \"S3\", \"location\": \"$BUCKET\"},
    \"stages\": [
      {
        \"name\": \"Source\",
        \"actions\": [{
          \"name\": \"SourceAction\",
          \"actionTypeId\": {\"category\": \"Source\", \"owner\": \"AWS\", \"provider\": \"S3\", \"version\": \"1\"},
          \"outputArtifacts\": [{\"name\": \"SourceOutput\"}],
          \"configuration\": {\"S3Bucket\": \"$BUCKET\", \"S3ObjectKey\": \"source.zip\"}
        }]
      },
      {
        \"name\": \"Deploy\",
        \"actions\": [{
          \"name\": \"DeployAction\",
          \"actionTypeId\": {\"category\": \"Deploy\", \"owner\": \"AWS\", \"provider\": \"S3\", \"version\": \"1\"},
          \"inputArtifacts\": [{\"name\": \"SourceOutput\"}],
          \"configuration\": {\"BucketName\": \"$BUCKET\", \"Extract\": \"true\"}
        }]
      }
    ]
  }" \
  --query 'pipeline.{Name:name,Version:version}' \
  --output table
echo "  ✓ Pipeline created"

# ── Get pipeline state ────────────────────────────────
echo "▶ Getting pipeline state..."
$AWS codepipeline get-pipeline-state \
  --name "$PIPELINE" \
  --query 'stageStates[].{Stage:stageName,Status:latestExecution.status}' \
  --output table

# ── Tag the pipeline ──────────────────────────────────
echo "▶ Tagging pipeline..."
PIPELINE_ARN="arn:aws:codepipeline:us-east-1:${ACCOUNT}:${PIPELINE}"
$AWS codepipeline tag-resource \
  --resource-arn "$PIPELINE_ARN" \
  --tags key=Env,value=demo key=Team,value=platform \
  > /dev/null
echo "  ✓ Tags applied"

# ── List pipelines ────────────────────────────────────
echo "▶ Listing all pipelines..."
$AWS codepipeline list-pipelines \
  --query 'pipelines[].{Name:name,Version:version,Updated:updated}' \
  --output table

echo ""
echo "  ✅  CodePipeline demo complete"
echo ""

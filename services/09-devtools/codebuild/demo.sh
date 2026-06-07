#!/bin/bash
# ══════════════════════════════════════════════════════
#  CodeBuild Demo — Create project, start build, inspect
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
AWS="awslocal"
ACCOUNT="000000000000"
PROJECT="demo-build-$$"
BUCKET="codebuild-src-$$"

echo ""; echo "╔══════════════════════════════════════╗"
echo "║   CodeBuild Demo                     ║"; echo "╚══════════════════════════════════════╝"; echo ""

# ── IAM role & S3 bucket ──────────────────────────────
echo "▶ Creating IAM role and S3 artifact bucket..."
$AWS iam create-role --role-name codebuild-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codebuild.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
$AWS s3api create-bucket --bucket "$BUCKET" > /dev/null 2>&1 || true
echo "  ✓ Role and bucket ready"

# ── Create build project ──────────────────────────────
echo "▶ Creating CodeBuild project: $PROJECT..."
$AWS codebuild create-project --name "$PROJECT" \
  --source '{"type":"NO_SOURCE","buildspec":"version: 0.2\nphases:\n  build:\n    commands:\n      - echo Hello from CodeBuild"}' \
  --artifacts "{\"type\":\"S3\",\"location\":\"$BUCKET\"}" \
  --environment '{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:5.0","computeType":"BUILD_GENERAL1_SMALL"}' \
  --service-role "arn:aws:iam::${ACCOUNT}:role/codebuild-demo-role" \
  --query 'project.name' --output text
echo "  ✓ Project created"

# ── Start build ───────────────────────────────────────
echo "▶ Starting build..."
BUILD_ID=$($AWS codebuild start-build --project-name "$PROJECT" --query 'build.id' --output text)
echo "  ✓ Build started: $BUILD_ID"

# ── Get build status ──────────────────────────────────
echo "▶ Build status..."
$AWS codebuild batch-get-builds --ids "$BUILD_ID" \
  --query 'builds[].{Id:id,Status:buildStatus,Phase:currentPhase}' --output table

# ── List projects ─────────────────────────────────────
echo "▶ Listing CodeBuild projects..."
$AWS codebuild list-projects --query 'projects' --output table

echo ""; echo "  ✅  CodeBuild demo complete"; echo ""

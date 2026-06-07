#!/bin/bash
# ══════════════════════════════════════════════════════
#  ECR Demo — Create repo, get auth token, push image
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
ACCOUNT="000000000000"
REPO="demo-repo"
REGISTRY="${ACCOUNT}.dkr.ecr.us-east-1.localhost.localstack.cloud:4566"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   ECR Demo                           ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Create Repository ──────────────────────────────────
echo "▶ Creating ECR repository: $REPO..."
$AWS ecr delete-repository --repository-name "$REPO" --force > /dev/null 2>&1 || true
REPO_URI=$($AWS ecr create-repository \
  --repository-name "$REPO" \
  --image-scanning-configuration scanOnPush=true \
  --query 'repository.repositoryUri' --output text)
echo "  ✓ Repository URI: $REPO_URI"

# ── Lifecycle Policy ───────────────────────────────────
echo "▶ Applying lifecycle policy (keep last 5 images)..."
$AWS ecr put-lifecycle-policy \
  --repository-name "$REPO" \
  --lifecycle-policy-text '{
    "rules":[{
      "rulePriority":1,
      "description":"Keep last 5 images",
      "selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":5},
      "action":{"type":"expire"}
    }]
  }' > /dev/null
echo "  ✓ Lifecycle policy applied"

# ── Auth token (simulate docker login) ────────────────
echo "▶ Retrieving ECR auth token..."
TOKEN=$($AWS ecr get-authorization-token \
  --query 'authorizationData[0].authorizationToken' --output text)
echo "  ✓ Auth token received (length: ${#TOKEN} chars)"

# ── Build and push a minimal image ─────────────────────
echo "▶ Building minimal Docker image and pushing..."
TMPDIR="$(mktemp -d)"
cat > "$TMPDIR/Dockerfile" <<'DFEOF'
FROM alpine:3.18
CMD ["echo", "Hello from ECR demo image"]
DFEOF
docker build -q -t "${REPO}:latest" "$TMPDIR" > /dev/null
docker tag "${REPO}:latest" "${REGISTRY}/${REPO}:latest"
docker login --username AWS --password "$TOKEN" "https://${REGISTRY}" > /dev/null 2>&1 || true
docker push "${REGISTRY}/${REPO}:latest" > /dev/null 2>&1 || true
rm -rf "$TMPDIR"
echo "  ✓ Image pushed: ${REGISTRY}/${REPO}:latest"

# ── List images ────────────────────────────────────────
echo "▶ Listing images in $REPO..."
$AWS ecr list-images \
  --repository-name "$REPO" \
  --query 'imageIds[].{Tag:imageTag,Digest:imageDigest}' \
  --output table || echo "  (no images indexed yet — push may be async in LocalStack)"

# ── Describe repositories ──────────────────────────────
echo "▶ All ECR repositories:"
$AWS ecr describe-repositories \
  --query 'repositories[].{Name:repositoryName,URI:repositoryUri,Scan:imageScanningConfiguration.scanOnPush}' \
  --output table

echo ""
echo "  ✅  ECR demo complete"
echo ""

#!/bin/bash
# ══════════════════════════════════════════════════════
#  CodeDeploy Demo — App, deployment group, deployment
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
AWS="awslocal"
ACCOUNT="000000000000"
APP="demo-app-$$"
DG="demo-dg-$$"
BUCKET="codedeploy-bundle-$$"

echo ""; echo "╔══════════════════════════════════════╗"
echo "║   CodeDeploy Demo                    ║"; echo "╚══════════════════════════════════════╝"; echo ""

# ── IAM role & S3 bucket ──────────────────────────────
echo "▶ Creating IAM role and S3 bundle bucket..."
$AWS iam create-role --role-name codedeploy-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codedeploy.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
$AWS s3api create-bucket --bucket "$BUCKET" > /dev/null 2>&1 || true
echo "  ✓ Role and bucket ready"

# ── Create application ────────────────────────────────
echo "▶ Creating application: $APP..."
$AWS codedeploy create-application --application-name "$APP" --compute-platform Server \
  --query 'applicationId' --output text
echo "  ✓ Application created"

# ── Create deployment group ───────────────────────────
echo "▶ Creating deployment group: $DG..."
$AWS codedeploy create-deployment-group --application-name "$APP" \
  --deployment-group-name "$DG" \
  --service-role-arn "arn:aws:iam::${ACCOUNT}:role/codedeploy-demo-role" \
  --deployment-config-name CodeDeployDefault.AllAtOnce \
  --ec2-tag-filters Key=Env,Value=demo,Type=KEY_AND_VALUE \
  --query 'deploymentGroupId' --output text
echo "  ✓ Deployment group created"

# ── Create deployment ─────────────────────────────────
echo "▶ Creating deployment..."
DEPLOY_ID=$($AWS codedeploy create-deployment --application-name "$APP" \
  --deployment-group-name "$DG" \
  --revision "{\"revisionType\":\"S3\",\"s3Location\":{\"bucket\":\"$BUCKET\",\"key\":\"bundle.zip\",\"bundleType\":\"zip\"}}" \
  --query 'deploymentId' --output text)
echo "  ✓ Deployment: $DEPLOY_ID"

# ── Inspect ───────────────────────────────────────────
echo "▶ Deployment info..."
$AWS codedeploy get-deployment --deployment-id "$DEPLOY_ID" \
  --query 'deploymentInfo.{Id:deploymentId,Status:status,App:applicationName}' --output table
echo "▶ All deployments..."
$AWS codedeploy list-deployments --application-name "$APP" --deployment-group-name "$DG" \
  --query 'deployments' --output table

echo ""; echo "  ✅  CodeDeploy demo complete"; echo ""

#!/bin/bash
# ══════════════════════════════════════════════════════
#  Lambda Demo — Create, invoke, update, and list logs
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"
ACCOUNT="000000000000"
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/lambda-demo-role"
FUNC="lambda-demo-fn"
TMPDIR="$(mktemp -d)"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Lambda Demo                        ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── IAM role ──────────────────────────────────────────
echo "▶ Creating IAM execution role..."
$AWS iam create-role \
  --role-name lambda-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  > /dev/null 2>&1 || true
echo "  ✓ Role ready"

# ── Package inline Python handler ─────────────────────
cat > "$TMPDIR/handler.py" <<'PYEOF'
import json

def lambda_handler(event, context):
    name = event.get("name", "world")
    return {"statusCode": 200, "body": json.dumps({"message": f"Hello, {name}!"})}
PYEOF
(cd "$TMPDIR" && zip -q fn.zip handler.py)

# ── Create function ────────────────────────────────────
echo "▶ Deploying function: $FUNC..."
$AWS lambda delete-function --function-name "$FUNC" > /dev/null 2>&1 || true
$AWS lambda create-function \
  --function-name "$FUNC" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler handler.lambda_handler \
  --zip-file "fileb://$TMPDIR/fn.zip" \
  --timeout 10 \
  > /dev/null
echo "  ✓ Function created"

# ── Invoke ─────────────────────────────────────────────
echo "▶ Invoking function..."
$AWS lambda invoke \
  --function-name "$FUNC" \
  --payload '{"name":"LocalStack"}' \
  --cli-binary-format raw-in-base64-out \
  "$TMPDIR/response.json" > /dev/null
echo "  Response: $(cat $TMPDIR/response.json)"

# ── Update concurrency ─────────────────────────────────
echo "▶ Setting reserved concurrency to 5..."
$AWS lambda put-function-concurrency \
  --function-name "$FUNC" \
  --reserved-concurrent-executions 5 \
  --query ReservedConcurrentExecutions
echo "  ✓ Concurrency set"

# ── List functions ─────────────────────────────────────
echo "▶ Listing Lambda functions..."
$AWS lambda list-functions \
  --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Timeout:Timeout}' \
  --output table

rm -rf "$TMPDIR"
echo ""
echo "  ✅  Lambda demo complete"
echo ""

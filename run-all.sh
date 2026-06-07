#!/bin/bash
# Run all AWS service demos
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

SERVICES_DIR="$(cd "$(dirname "$0")/services" && pwd)"
PASS=0
FAIL=0
SKIP=0

for demo in $(find "$SERVICES_DIR" -name "demo.sh" | sort); do
  service=$(dirname "$demo" | xargs basename)
  category=$(dirname "$demo" | xargs dirname | xargs basename)
  echo ""
  echo "════════════════════════════════════════"
  echo "  $category / $service"
  echo "════════════════════════════════════════"
  if bash "$demo"; then
    echo "  ✅ PASSED"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAILED"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "════════════════════════════════════════"

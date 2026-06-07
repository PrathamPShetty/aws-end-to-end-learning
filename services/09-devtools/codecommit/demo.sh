#!/bin/bash
# ══════════════════════════════════════════════════════
#  CodeCommit Demo — Create repo, commit files, inspect
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
AWS="awslocal"
REPO="demo-repo-$$"

echo ""; echo "╔══════════════════════════════════════╗"
echo "║   CodeCommit Demo                    ║"; echo "╚══════════════════════════════════════╝"; echo ""

# ── Create repository ─────────────────────────────────
echo "▶ Creating repository: $REPO..."
$AWS codecommit create-repository --repository-name "$REPO" \
  --repository-description "LocalStack CodeCommit demo" \
  --query 'repositoryMetadata.{Name:repositoryName}' --output table
echo "  ✓ Repository created"

# ── Initial commit ────────────────────────────────────
echo "▶ Committing README to main..."
$AWS codecommit put-file --repository-name "$REPO" --branch-name main \
  --file-content "# Demo Repo" --file-path "README.md" \
  --commit-message "Initial commit" --query 'commitId' --output text
echo "  ✓ README committed"

# ── Second commit ─────────────────────────────────────
echo "▶ Committing src/app.py..."
COMMIT_ID=$($AWS codecommit put-file --repository-name "$REPO" --branch-name main \
  --file-content "print('Hello from LocalStack!')" --file-path "src/app.py" \
  --commit-message "Add app.py" --query 'commitId' --output text)
echo "  ✓ app.py committed (commitId: $COMMIT_ID)"

# ── Inspect ───────────────────────────────────────────
echo "▶ Listing branches..."; $AWS codecommit list-branches --repository-name "$REPO" --output table
echo "▶ Commit details..."
$AWS codecommit get-commit --repository-name "$REPO" --commit-id "$COMMIT_ID" \
  --query 'commit.{Message:message}' --output table
echo "▶ All repositories..."; $AWS codecommit list-repositories --query 'repositories[].repositoryName' --output table

echo ""; echo "  ✅  CodeCommit demo complete"; echo ""

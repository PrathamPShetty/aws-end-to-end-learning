#!/bin/bash
# ============================================================
# AWS Glacier - Long-term Archive Storage Demo
# Purpose: Cold storage for archival data - create vaults,
#          upload archives, initiate retrieval jobs
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

VAULT="demo-glacier-vault-$$"
ACCOUNT_ID="-"

echo "==> Creating Glacier vault: $VAULT"
awslocal glacier create-vault \
  --account-id "$ACCOUNT_ID" \
  --vault-name "$VAULT"

echo ""
echo "==> Listing vaults"
awslocal glacier list-vaults \
  --account-id "$ACCOUNT_ID" \
  --query 'VaultList[].{Name:VaultName,Size:SizeInBytes,Archives:NumberOfArchives}' \
  --output table

echo ""
echo "==> Uploading an archive to the vault"
echo "This is archived data - $(date)" > /tmp/glacier-archive-$$.txt
UPLOAD_RESP=$(awslocal glacier upload-archive \
  --account-id "$ACCOUNT_ID" \
  --vault-name "$VAULT" \
  --body /tmp/glacier-archive-$$.txt \
  --archive-description "Demo archive $(date +%Y-%m-%d)")
rm -f /tmp/glacier-archive-$$.txt

ARCHIVE_ID=$(echo "$UPLOAD_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['archiveId'])")
echo "Uploaded archive ID: $ARCHIVE_ID"

echo ""
echo "==> Initiating an inventory retrieval job"
awslocal glacier initiate-job \
  --account-id "$ACCOUNT_ID" \
  --vault-name "$VAULT" \
  --job-parameters '{"Type":"inventory-retrieval","Description":"Demo inventory job"}'

echo ""
echo "==> Cleanup: deleting archive and vault"
awslocal glacier delete-archive \
  --account-id "$ACCOUNT_ID" \
  --vault-name "$VAULT" \
  --archive-id "$ARCHIVE_ID" || true
awslocal glacier delete-vault \
  --account-id "$ACCOUNT_ID" \
  --vault-name "$VAULT" || true

echo ""
echo "Done. Glacier demo complete."

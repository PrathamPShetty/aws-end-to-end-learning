#!/bin/bash
# ============================================================
# Service: KMS (Key Management Service)
# Purpose: Create and use customer-managed keys for encryption
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ALIAS_NAME="alias/demo-key"
PLAINTEXT="HelloSecretWorld"

echo "==> Creating KMS symmetric key"
KEY_ID=$(awslocal kms create-key \
  --description "Demo encryption key" \
  --key-usage ENCRYPT_DECRYPT \
  --query 'KeyMetadata.KeyId' \
  --output text)
echo "    Key ID: $KEY_ID"

echo "==> Creating alias for the key"
awslocal kms create-alias \
  --alias-name "$ALIAS_NAME" \
  --target-key-id "$KEY_ID" 2>/dev/null || true

echo "==> Encrypting plaintext"
CIPHERTEXT=$(awslocal kms encrypt \
  --key-id "$KEY_ID" \
  --plaintext "$PLAINTEXT" \
  --query 'CiphertextBlob' \
  --output text)
echo "    Ciphertext (base64): $CIPHERTEXT"

echo "==> Decrypting ciphertext"
DECRYPTED=$(awslocal kms decrypt \
  --ciphertext-blob "$CIPHERTEXT" \
  --query 'Plaintext' \
  --output text)
echo "    Decrypted (base64): $DECRYPTED"
echo "    Decoded: $(echo "$DECRYPTED" | base64 --decode)"

echo "==> Describing the key"
awslocal kms describe-key --key-id "$KEY_ID" \
  --query 'KeyMetadata.{KeyId:KeyId,State:KeyState,Usage:KeyUsage}'

echo "==> Listing aliases"
awslocal kms list-aliases --key-id "$KEY_ID"

echo "==> KMS demo complete."

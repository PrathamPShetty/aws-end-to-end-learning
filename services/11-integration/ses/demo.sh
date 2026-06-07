#!/bin/bash
# ============================================================
# SES (Simple Email Service) Demo
# Purpose: Verify identities, send email, check send quota
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

FROM_EMAIL="sender@example.com"
TO_EMAIL="recipient@example.com"

echo "==> Verifying email identities..."
awslocal ses verify-email-identity --email-address "$FROM_EMAIL"
awslocal ses verify-email-identity --email-address "$TO_EMAIL"
echo "  Identities submitted"

echo "==> Listing verified identities..."
awslocal ses list-identities --query 'Identities' --output table

echo "==> Sending HTML email..."
MSG_ID=$(awslocal ses send-email \
  --from "$FROM_EMAIL" \
  --destination "ToAddresses=$TO_EMAIL" \
  --message '{
    "Subject": {"Data": "Hello from LocalStack SES", "Charset": "UTF-8"},
    "Body": {
      "Text": {"Data": "Demo email via LocalStack SES.", "Charset": "UTF-8"},
      "Html": {"Data": "<h1>Hello!</h1><p>Demo from <b>LocalStack SES</b>.</p>", "Charset": "UTF-8"}
    }
  }' --output text --query 'MessageId')
echo "  Message ID: $MSG_ID"

echo "==> Sending second email to check quota usage..."
awslocal ses send-email \
  --from "$FROM_EMAIL" \
  --destination "ToAddresses=$TO_EMAIL" \
  --message '{"Subject":{"Data":"Test #2"},"Body":{"Text":{"Data":"Second test message."}}}' \
  --output text --query 'MessageId'

echo "==> Send quota..."
awslocal ses get-send-quota \
  --query '{Max24HrSend:Max24HourSend,MaxSendRate:MaxSendRate,SentLast24Hrs:SentLast24Hours}' \
  --output table

echo "==> SES demo complete."

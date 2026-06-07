#!/bin/bash
# ============================================================
# Service: ACM (AWS Certificate Manager)
# Purpose: Provision and manage SSL/TLS certificates
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

DOMAIN="demo.example.com"
ALT_DOMAIN="*.demo.example.com"

echo "==> Requesting a public certificate"
CERT_ARN=$(awslocal acm request-certificate \
  --domain-name "$DOMAIN" \
  --subject-alternative-names "$ALT_DOMAIN" \
  --validation-method DNS \
  --query 'CertificateArn' \
  --output text)
echo "    Certificate ARN: $CERT_ARN"

echo "==> Describing the certificate"
awslocal acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --query 'Certificate.{Domain:DomainName,Status:Status,SANs:SubjectAlternativeNames}'

echo "==> Adding tags to the certificate"
awslocal acm add-tags-to-certificate \
  --certificate-arn "$CERT_ARN" \
  --tags Key=env,Value=demo Key=project,Value=security-demo

echo "==> Listing tags on the certificate"
awslocal acm list-tags-for-certificate \
  --certificate-arn "$CERT_ARN"

echo "==> Listing all certificates"
awslocal acm list-certificates \
  --query 'CertificateSummaryList[*].{ARN:CertificateArn,Domain:DomainName}'

echo "==> ACM demo complete."

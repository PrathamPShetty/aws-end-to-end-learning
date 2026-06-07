# AWS ACM (Certificate Manager)

## What is it?
AWS Certificate Manager (ACM) is a fully managed service that provisions, manages, and deploys SSL/TLS certificates for use with AWS services such as Application Load Balancers, CloudFront distributions, and API Gateway. ACM can issue public certificates for free (validated by DNS or email) and will automatically renew them before they expire, eliminating the operational burden of manual certificate lifecycle management. You can also import third-party certificates purchased outside AWS. The main benefit is zero-cost public TLS certificates that renew themselves, reducing both cost and the risk of unexpected certificate expiry outages.

## Key Concepts
- **Certificate** — An SSL/TLS certificate stored in ACM, identified by an ARN; can be AWS-issued (public or private) or imported.
- **Domain Name** — The primary FQDN the certificate protects (e.g., `api.example.com`).
- **Subject Alternative Names (SANs)** — Additional domains or wildcards covered by the same certificate (e.g., `*.example.com`).
- **Validation Method** — The mechanism ACM uses to prove you control the domain: `DNS` (add a CNAME record) or `EMAIL` (respond to an email sent to domain contacts).
- **Certificate Status** — The lifecycle state: `PENDING_VALIDATION` → `ISSUED` → `EXPIRED` / `REVOKED`.
- **ACM Private CA** — A separate feature to run your own internal Certificate Authority for issuing private certificates to internal services.

## When to Use
- Enabling HTTPS on an Application Load Balancer so all traffic between clients and your web application is encrypted.
- Securing a custom domain on API Gateway (`api.myapp.com`) with a trusted certificate at no extra cost.
- Attaching a wildcard certificate (`*.myapp.com`) to a CloudFront distribution to cover all subdomains.
- Importing a certificate purchased from an external CA (e.g., DigiCert) for use with AWS services that require ACM-managed certs.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Request public certificate | `awslocal acm request-certificate --domain-name api.example.com --validation-method DNS` |
| Request with SANs | `awslocal acm request-certificate --domain-name example.com --subject-alternative-names "*.example.com" "www.example.com" --validation-method DNS` |
| List certificates | `awslocal acm list-certificates` |
| Describe certificate | `awslocal acm describe-certificate --certificate-arn <arn>` |
| Add tags | `awslocal acm add-tags-to-certificate --certificate-arn <arn> --tags Key=env,Value=prod` |
| List tags | `awslocal acm list-tags-for-certificate --certificate-arn <arn>` |
| Import certificate | `awslocal acm import-certificate --certificate fileb://cert.pem --private-key fileb://key.pem --certificate-chain fileb://chain.pem` |
| Delete certificate | `awslocal acm delete-certificate --certificate-arn <arn>` |

## Example Walkthrough

1. **Request a public certificate for a primary domain**
   ```bash
   CERT_ARN=$(awslocal acm request-certificate \
     --domain-name api.example.com \
     --validation-method DNS \
     --query 'CertificateArn' \
     --output text)
   echo "Certificate ARN: $CERT_ARN"
   ```
   Submits a certificate request. The certificate starts in `PENDING_VALIDATION` status until the DNS CNAME record is added.

2. **Add Subject Alternative Names (SANs) for a wildcard and www**
   ```bash
   CERT_ARN=$(awslocal acm request-certificate \
     --domain-name example.com \
     --subject-alternative-names "*.example.com" "api.example.com" \
     --validation-method DNS \
     --query 'CertificateArn' \
     --output text)
   ```
   One certificate covers the apex domain plus all subdomains with a single wildcard SAN.

3. **Describe the certificate to retrieve its DNS validation record**
   ```bash
   awslocal acm describe-certificate \
     --certificate-arn "$CERT_ARN" \
     --query 'Certificate.{Domain:DomainName,Status:Status,ValidationOptions:DomainValidationOptions}'
   ```
   Shows the CNAME name and value you must add to your DNS provider to complete DNS validation.

4. **Tag the certificate for environment and project tracking**
   ```bash
   awslocal acm add-tags-to-certificate \
     --certificate-arn "$CERT_ARN" \
     --tags Key=env,Value=prod Key=project,Value=storefront Key=team,Value=platform
   ```
   Tags help you identify which certificate belongs to which project when you have dozens in an account.

5. **List all certificates in the account**
   ```bash
   awslocal acm list-certificates \
     --query 'CertificateSummaryList[*].{ARN:CertificateArn,Domain:DomainName,Status:Status}'
   ```
   Provides a summary table of every certificate — useful for auditing or finding the ARN to attach to a load balancer.

6. **Delete a certificate that is no longer in use**
   ```bash
   awslocal acm delete-certificate --certificate-arn "$CERT_ARN"
   ```
   Removes the certificate from ACM. Certificates currently associated with AWS resources cannot be deleted.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--domain-name` | Primary FQDN for the certificate (e.g., `app.example.com`) |
| `--subject-alternative-names` | Space-separated list of additional domains or wildcards |
| `--validation-method` | `DNS` (add a CNAME record) or `EMAIL` (respond to a verification email) |
| `--certificate-arn` | ARN of an existing certificate to describe, tag, or delete |
| `--tags` | Space-separated `Key=k,Value=v` pairs |
| `--certificate` | `fileb://cert.pem` — PEM-encoded certificate body for import |
| `--private-key` | `fileb://key.pem` — PEM-encoded private key for import |
| `--certificate-chain` | `fileb://chain.pem` — PEM-encoded certificate chain for import |
| `--includes` | Filter in `list-certificates` by key usage or extended key usage |

## How to Run the Demo
```bash
cd services/06-security/acm
bash demo.sh
```

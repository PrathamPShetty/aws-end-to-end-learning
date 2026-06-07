# Amazon SES (Simple Email Service)

## What is it?
Amazon Simple Email Service (SES) is a cloud-based email sending and receiving platform designed for high-volume, transactional, and marketing email delivery. It provides an API and SMTP interface so your application can send email without running your own mail server or managing deliverability infrastructure. SES handles bounce and complaint tracking, DKIM/SPF signing, and sending reputation monitoring. It is the right choice when you need to send password resets, order confirmations, alerts, or newsletter campaigns reliably at scale.

## Key Concepts
- **Identity** — a domain (example.com) or an email address (sender@example.com) that SES verifies before allowing you to send from it.
- **Send Quota** — the maximum number of emails you can send per 24-hour period and per second; increases are requested via the AWS console.
- **Configuration Set** — a named group of rules that applies tracking (open/click), event publishing, and reputation settings to a batch of emails.
- **Suppression List** — a per-account list of addresses that have previously bounced or complained; SES automatically skips these addresses.
- **Template** — a reusable HTML/text email body with Handlebars-style substitution variables for personalised bulk sending.
- **Raw vs. Formatted Sending** — `send-email` accepts structured subject/body objects; `send-raw-email` accepts a fully formed MIME message for attachments and custom headers.

## When to Use
- **Transactional email** — send order confirmations, shipping updates, and password-reset links triggered by application events.
- **Bulk marketing campaigns** — deliver newsletters and promotional emails to large subscriber lists using templates and personalisation variables.
- **Application alerts and notifications** — email CloudWatch alarm notifications, error reports, or CI/CD build results through a programmatic API call.
- **Inbound email processing** — receive email for your domain, store it in S3 or trigger a Lambda function via SES receipt rules.

## CLI Quick Reference (awslocal)

### Verify an email identity
```bash
awslocal ses verify-email-identity \
  --email-address sender@example.com
```

### Verify a domain identity
```bash
awslocal ses verify-domain-identity \
  --domain example.com
```

### List verified identities
```bash
awslocal ses list-identities \
  --query 'Identities' \
  --output table
```

### Send an email
```bash
awslocal ses send-email \
  --from sender@example.com \
  --destination "ToAddresses=recipient@example.com" \
  --message '{
    "Subject": {"Data": "Hello from SES", "Charset": "UTF-8"},
    "Body": {
      "Text": {"Data": "Plain-text body.", "Charset": "UTF-8"},
      "Html": {"Data": "<h1>Hello!</h1><p>HTML body.</p>", "Charset": "UTF-8"}
    }
  }'
```

### Get send quota
```bash
awslocal ses get-send-quota \
  --query '{Max24HrSend:Max24HourSend,MaxSendRate:MaxSendRate,SentLast24Hrs:SentLast24Hours}' \
  --output table
```

### Get send statistics
```bash
awslocal ses get-send-statistics \
  --query 'SendDataPoints[].{Timestamp:Timestamp,DeliveryAttempts:DeliveryAttempts,Bounces:Bounces,Complaints:Complaints}' \
  --output table
```

### Delete an identity
```bash
awslocal ses delete-identity \
  --identity sender@example.com
```

## Example Walkthrough

1. **Verify the sender identity** — SES requires the sending address or domain to be verified before use.
   ```bash
   awslocal ses verify-email-identity --email-address sender@example.com
   ```

2. **Verify the recipient identity** — in LocalStack (sandbox mode) the recipient also needs verification.
   ```bash
   awslocal ses verify-email-identity --email-address recipient@example.com
   ```

3. **Confirm both identities appear as verified** — list all verified identities.
   ```bash
   awslocal ses list-identities \
     --query 'Identities' \
     --output table
   ```

4. **Send a plain-text and HTML email** — capture the message ID returned by SES.
   ```bash
   MSG_ID=$(awslocal ses send-email \
     --from sender@example.com \
     --destination "ToAddresses=recipient@example.com" \
     --message '{
       "Subject": {"Data": "Hello from LocalStack SES", "Charset": "UTF-8"},
       "Body": {
         "Text": {"Data": "Demo email via LocalStack SES.", "Charset": "UTF-8"},
         "Html": {"Data": "<h1>Hello!</h1><p>Demo from <b>LocalStack SES</b>.</p>", "Charset": "UTF-8"}
       }
     }' --output text --query 'MessageId')
   echo "Message ID: $MSG_ID"
   ```

5. **Send a second email** — verify the sent count increments.
   ```bash
   awslocal ses send-email \
     --from sender@example.com \
     --destination "ToAddresses=recipient@example.com" \
     --message '{"Subject":{"Data":"Test #2"},"Body":{"Text":{"Data":"Second test message."}}}' \
     --output text --query 'MessageId'
   ```

6. **Check send quota usage** — confirm the SentLast24Hours counter reflects both sends.
   ```bash
   awslocal ses get-send-quota \
     --query '{Max24HrSend:Max24HourSend,MaxSendRate:MaxSendRate,SentLast24Hrs:SentLast24Hours}' \
     --output table
   ```

7. **Clean up** — delete the verified identities.
   ```bash
   awslocal ses delete-identity --identity sender@example.com
   awslocal ses delete-identity --identity recipient@example.com
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--email-address` | Email address to verify as a sending identity | `sender@example.com` |
| `--domain` | Domain to verify as a sending identity | `example.com` |
| `--from` | Verified sender address used in the `From` header | `sender@example.com` |
| `--destination` | Comma-separated recipient addresses (`ToAddresses`, `CcAddresses`, `BccAddresses`) | `ToAddresses=a@b.com` |
| `--message` | JSON object with `Subject` and `Body` (Text/Html) sub-objects | See send-email example |
| `--configuration-set-name` | Apply a configuration set for tracking/events | `my-config-set` |
| `--reply-to-addresses` | Override the Reply-To header | `reply@example.com` |
| `--return-path` | Bounce-notification recipient address | `bounces@example.com` |
| `--raw-message` | Full MIME message bytes for attachments (`send-raw-email`) | `Data=fileb://email.mime` |
| `--template` | Name of a pre-registered template (`send-templated-email`) | `WelcomeTemplate` |

## How to Run the Demo

```bash
cd services/11-integration/ses
bash demo.sh
```

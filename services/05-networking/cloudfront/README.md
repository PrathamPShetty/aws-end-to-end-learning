# Amazon CloudFront

## What is it?
Amazon CloudFront is a global Content Delivery Network (CDN) that distributes your content — static files, APIs, video streams, or entire web applications — from edge locations physically close to your users, dramatically reducing latency. CloudFront caches responses at the edge so origin servers (S3, EC2, ALB, or any HTTP endpoint) receive far fewer requests, lowering both cost and load. It also provides built-in HTTPS termination, custom domain support, and integration with AWS WAF for security. Use CloudFront whenever you need fast, global delivery of content or want to shield your origin from direct internet traffic.

## Key Concepts
- **Distribution** — The top-level CloudFront resource. It defines your origins, cache behaviors, and domain names. Each distribution gets a unique `*.cloudfront.net` domain.
- **Origin** — The source of truth for your content. Can be an S3 bucket, an Application Load Balancer, an EC2 instance, or any public HTTP server.
- **Cache Behavior** — A rule that maps a URL path pattern (e.g., `/images/*`) to an origin and specifies caching settings, allowed HTTP methods, and viewer protocol policies.
- **Edge Location** — One of CloudFront's globally distributed PoPs (Points of Presence) where content is cached and served to nearby users.
- **TTL (Time to Live)** — How long CloudFront keeps a cached object before re-fetching from the origin (`MinTTL`, `DefaultTTL`, `MaxTTL`).
- **Viewer Protocol Policy** — Controls how end-users connect to CloudFront: `allow-all`, `https-only`, or `redirect-to-https`.

## When to Use
- **Static website hosting** — Serve HTML, CSS, JS, and images from S3 via CloudFront for fast global load times with HTTPS.
- **API acceleration** — Cache or pass through API Gateway/ALB responses at the edge, reducing round-trip time for geographically dispersed clients.
- **Large file / media distribution** — Deliver software downloads, video-on-demand, or live streaming efficiently using CloudFront's global edge network.
- **Origin shielding** — Use CloudFront as a reverse proxy so your origin server is never directly exposed to the internet, protecting against DDoS and scraping.

## CLI Quick Reference (awslocal)

### Distribution Operations
| Operation | Command |
|-----------|---------|
| Create distribution | `awslocal cloudfront create-distribution --distribution-config file://dist-config.json` |
| List distributions | `awslocal cloudfront list-distributions` |
| Get distribution | `awslocal cloudfront get-distribution --id <dist-id>` |
| Update distribution | `awslocal cloudfront update-distribution --id <dist-id> --distribution-config file://updated.json --if-match <etag>` |
| Delete distribution | `awslocal cloudfront delete-distribution --id <dist-id> --if-match <etag>` |

### Inline example — create distribution backed by S3
```bash
awslocal cloudfront create-distribution \
  --distribution-config '{
    "CallerReference": "ref-001",
    "Origins": {
      "Quantity": 1,
      "Items": [{
        "Id": "s3-origin",
        "DomainName": "my-bucket.s3.amazonaws.com",
        "S3OriginConfig": {"OriginAccessIdentity": ""}
      }]
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "s3-origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "ForwardedValues": {
        "QueryString": false,
        "Cookies": {"Forward": "none"}
      },
      "MinTTL": 0
    },
    "Comment": "My CDN",
    "Enabled": true
  }'
```

## Example Walkthrough

1. **Create an S3 bucket to serve as the origin**
   ```bash
   BUCKET="cf-origin-demo-bucket"
   awslocal s3 mb "s3://$BUCKET"
   ```
   Provisions the S3 bucket that CloudFront will pull content from.

2. **Upload a sample HTML file to the bucket**
   ```bash
   echo "<html><body>Hello from CloudFront demo</body></html>" | \
     awslocal s3 cp - "s3://$BUCKET/index.html" --content-type "text/html"
   ```
   Places a file at the origin so CloudFront has something to cache and serve.

3. **Create the CloudFront distribution pointing to the S3 origin**
   ```bash
   DIST=$(awslocal cloudfront create-distribution \
     --distribution-config "{
       \"CallerReference\": \"ref-$(date +%s)\",
       \"Origins\": {
         \"Quantity\": 1,
         \"Items\": [{
           \"Id\": \"s3-origin\",
           \"DomainName\": \"${BUCKET}.s3.amazonaws.com\",
           \"S3OriginConfig\": {\"OriginAccessIdentity\": \"\"}
         }]
       },
       \"DefaultCacheBehavior\": {
         \"TargetOriginId\": \"s3-origin\",
         \"ViewerProtocolPolicy\": \"redirect-to-https\",
         \"ForwardedValues\": {
           \"QueryString\": false,
           \"Cookies\": {\"Forward\": \"none\"}
         },
         \"MinTTL\": 0
       },
       \"Comment\": \"Demo distribution\",
       \"Enabled\": true
     }")
   ```
   Creates the distribution. CloudFront returns a unique distribution ID and a `*.cloudfront.net` domain.

4. **Extract the distribution ID and domain**
   ```bash
   DIST_ID=$(echo "$DIST" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])")
   DOMAIN=$(echo "$DIST" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['DomainName'])")
   echo "ID: $DIST_ID  Domain: $DOMAIN"
   ```
   Parses the JSON response to get values needed for subsequent operations.

5. **List all distributions to verify creation**
   ```bash
   awslocal cloudfront list-distributions \
     --query 'DistributionList.Items[*].{ID:Id,Domain:DomainName,Status:Status}' \
     --output table
   ```
   Displays a summary of every CloudFront distribution in your account.

6. **Inspect the distribution configuration**
   ```bash
   awslocal cloudfront get-distribution --id "$DIST_ID" \
     --query 'Distribution.{Id:Id,Status:Status,DomainName:DomainName}' \
     --output table
   ```
   Retrieves current configuration and deployment status (`InProgress` or `Deployed`).

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--distribution-config` | Full JSON config object or `file://path.json` reference |
| `CallerReference` | Unique string to prevent duplicate distribution creation |
| `Origins.Items[].DomainName` | The hostname of your origin (S3 bucket URL, ALB DNS, etc.) |
| `ViewerProtocolPolicy` | `allow-all`, `https-only`, or `redirect-to-https` |
| `MinTTL` / `DefaultTTL` / `MaxTTL` | Cache duration in seconds at the edge |
| `ForwardedValues.QueryString` | Whether to include query strings in the cache key |
| `Enabled` | `true` to activate the distribution, `false` to disable it |
| `--if-match` | ETag required for update/delete operations (prevents concurrent edits) |

## How to Run the Demo
```bash
cd services/05-networking/cloudfront
bash demo.sh
```

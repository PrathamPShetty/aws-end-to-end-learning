# AWS WAF (Web Application Firewall)

## What is it?
AWS WAF is a web application firewall that protects your web applications and APIs against common exploits and bots that can compromise security, affect availability, or consume excessive resources. It lets you define customizable rules — such as blocking specific IP ranges, filtering requests by geographic origin, rate-limiting clients, or matching SQL injection and XSS patterns — that are evaluated on every HTTP request before it reaches your application. WAF rules can be attached to Amazon CloudFront, Application Load Balancers, API Gateway, or AWS AppSync. Use it whenever your application is exposed to internet traffic and you need a programmable security layer in front of it.

## Key Concepts
- **WebACL (Web Access Control List)** — The top-level WAF resource. A WebACL contains an ordered list of rules and a default action (`Allow` or `Block`) for requests that match no rule.
- **Rule** — A single inspection unit within a WebACL. Each rule has a priority, a statement (the matching logic), and an action (`Allow`, `Block`, `Count`, or `CAPTCHA`).
- **Statement** — The condition a rule checks. Examples: `IPSetReferenceStatement`, `RateBasedStatement`, `SqliMatchStatement`, `GeoMatchStatement`, `ByteMatchStatement`.
- **IP Set** — A reusable list of IPv4 or IPv6 CIDR ranges that can be referenced by rules to allow or block traffic from those addresses.
- **Scope** — Either `REGIONAL` (for ALB, API Gateway, AppSync) or `CLOUDFRONT` (for CloudFront distributions; must be in `us-east-1`).
- **Visibility Config** — Per-rule and per-WebACL setting that enables CloudWatch metrics and sampled request logging for observability.

## When to Use
- **Block known malicious IPs** — Maintain an IP set of threat actors and blocklist them across all your applications using a single reusable WAF rule.
- **Rate limiting** — Prevent brute-force login attacks or API abuse by blocking IPs that exceed a configured number of requests per 5-minute window.
- **OWASP Top 10 protection** — Enable AWS Managed Rule Groups (e.g., `AWSManagedRulesCommonRuleSet`) to automatically block SQL injection, XSS, and other common web attacks.
- **Geographic restriction** — Allow traffic only from countries relevant to your service, blocking all other regions with a `GeoMatchStatement`.

## CLI Quick Reference (awslocal)

### IP Set Operations
| Operation | Command |
|-----------|---------|
| Create IP set | `awslocal wafv2 create-ip-set --name "blocked-ips" --scope REGIONAL --ip-address-version IPV4 --addresses "1.2.3.4/32"` |
| List IP sets | `awslocal wafv2 list-ip-sets --scope REGIONAL` |
| Get IP set | `awslocal wafv2 get-ip-set --name "blocked-ips" --scope REGIONAL --id <id>` |
| Delete IP set | `awslocal wafv2 delete-ip-set --name "blocked-ips" --scope REGIONAL --id <id> --lock-token <token>` |

### WebACL Operations
```bash
# Create a WebACL
awslocal wafv2 create-web-acl \
  --name "demo-web-acl" \
  --scope REGIONAL \
  --default-action '{"Allow": {}}' \
  --rules "[...]" \
  --visibility-config '{"SampledRequestsEnabled":true,"CloudWatchMetricsEnabled":true,"MetricName":"DemoACL"}'

# List WebACLs
awslocal wafv2 list-web-acls --scope REGIONAL

# Get WebACL
awslocal wafv2 get-web-acl --name "demo-web-acl" --scope REGIONAL --id <id>

# Delete WebACL
awslocal wafv2 delete-web-acl --name "demo-web-acl" --scope REGIONAL --id <id> --lock-token <token>
```

## Example Walkthrough

1. **Create an IP set with addresses to block**
   ```bash
   IP_SET=$(awslocal wafv2 create-ip-set \
     --name "blocked-ips" \
     --scope REGIONAL \
     --ip-address-version IPV4 \
     --addresses "192.168.1.100/32" "10.0.0.5/32")
   IP_SET_ID=$(echo "$IP_SET" | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['Id'])")
   IP_SET_ARN=$(echo "$IP_SET" | python3 -c "import sys,json; print(json.load(sys.stdin)['Summary']['ARN'])")
   echo "IP Set ID: $IP_SET_ID"
   ```
   Creates a named list of CIDR blocks that will be referenced by a WAF rule.

2. **Retrieve the LockToken for the IP set (required for updates)**
   ```bash
   LOCK_TOKEN=$(awslocal wafv2 list-ip-sets --scope REGIONAL \
     --query "IPSets[?Id=='$IP_SET_ID'].LockToken" --output text)
   echo "Lock Token: $LOCK_TOKEN"
   ```
   WAF uses optimistic locking; you must supply the current token to modify a resource.

3. **Create a WebACL with the IP block rule**
   ```bash
   awslocal wafv2 create-web-acl \
     --name "demo-web-acl" \
     --scope REGIONAL \
     --default-action '{"Allow": {}}' \
     --rules "[
       {
         \"Name\": \"block-bad-ips\",
         \"Priority\": 1,
         \"Statement\": {\"IPSetReferenceStatement\": {\"ARN\": \"$IP_SET_ARN\"}},
         \"Action\": {\"Block\": {}},
         \"VisibilityConfig\": {
           \"SampledRequestsEnabled\": true,
           \"CloudWatchMetricsEnabled\": true,
           \"MetricName\": \"BlockBadIPs\"
         }
       }
     ]" \
     --visibility-config '{
       "SampledRequestsEnabled": true,
       "CloudWatchMetricsEnabled": true,
       "MetricName": "DemoWebACL"
     }'
   ```
   Assembles the WebACL: by default allow all traffic, but block any IP in the blocked-ips set.

4. **List all WebACLs to confirm creation**
   ```bash
   awslocal wafv2 list-web-acls --scope REGIONAL \
     --query 'WebACLs[*].{Name:Name,Id:Id,ARN:ARN}' \
     --output table
   ```
   Shows every WebACL in the region with its name, ID, and ARN.

5. **List all IP sets**
   ```bash
   awslocal wafv2 list-ip-sets --scope REGIONAL \
     --query 'IPSets[*].{Name:Name,Id:Id}' \
     --output table
   ```
   Verifies the IP set was created and lists all IP sets available for reuse in rules.

6. **Associate the WebACL with an ALB (optional)**
   ```bash
   awslocal wafv2 associate-web-acl \
     --web-acl-arn <web-acl-arn> \
     --resource-arn <alb-arn>
   ```
   Attaches the WAF rules to a load balancer so all inbound traffic is inspected.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--scope` | `REGIONAL` (ALB/API Gateway) or `CLOUDFRONT` (must use us-east-1) |
| `--name` | Human-readable name for the WebACL, IP set, or rule group |
| `--default-action` | Action for requests that match no rule: `{"Allow": {}}` or `{"Block": {}}` |
| `--rules` | JSON array of rule objects with priority, statement, and action |
| `Priority` (in rule) | Lower number = evaluated first. Must be unique within the WebACL |
| `--ip-address-version` | `IPV4` or `IPV6` for IP sets |
| `--addresses` | Space-separated CIDR blocks (e.g., `"1.2.3.4/32" "10.0.0.0/8"`) |
| `--lock-token` | Optimistic concurrency token required for update and delete operations |
| `--visibility-config` | Enables CloudWatch metrics and sampled request logging per rule/ACL |

## How to Run the Demo
```bash
cd services/05-networking/waf
bash demo.sh
```

# Amazon Route 53

## What is it?
Amazon Route 53 is a scalable, highly available Domain Name System (DNS) web service that translates human-readable domain names (like `app.example.com`) into IP addresses that computers use to connect to each other. It also provides domain registration, health checking, and traffic routing policies such as weighted, latency-based, and failover routing. Route 53 is the entry point of your network architecture — every request from a user typically starts with a DNS lookup. Use it whenever you need reliable, programmable DNS management for your applications.

## Key Concepts
- **Hosted Zone** — A container for DNS records for a single domain (e.g., `example.com`). Can be public (internet-facing) or private (VPC-only).
- **Record Set** — A single DNS entry within a hosted zone (e.g., an A record mapping `app.example.com` to `10.0.0.1`).
- **Record Type** — The kind of DNS record: `A` (IPv4), `AAAA` (IPv6), `CNAME` (alias to another hostname), `MX` (mail), `TXT` (text/verification), `NS` (nameserver), `SOA` (start of authority).
- **TTL (Time to Live)** — How many seconds resolvers should cache a record before re-querying. Lower TTL = faster propagation of changes.
- **Routing Policy** — Strategy used when multiple records share the same name: Simple, Weighted, Latency, Failover, Geolocation, or Multivalue.
- **Health Check** — Monitors an endpoint and can trigger failover routing if the endpoint becomes unhealthy.

## When to Use
- **Custom domain for your application** — Point `api.myapp.com` to an EC2 instance, load balancer, or CloudFront distribution.
- **Blue/green or weighted deployments** — Split traffic between two versions of your app using weighted routing policies.
- **Disaster recovery / failover** — Automatically route traffic to a backup region when the primary becomes unhealthy using failover routing.
- **Private internal DNS in a VPC** — Use a private hosted zone so microservices can discover each other by name (e.g., `payments-service.internal`) without exposing records to the internet.

## CLI Quick Reference (awslocal)

### Hosted Zone Operations
| Operation | Command |
|-----------|---------|
| Create hosted zone | `awslocal route53 create-hosted-zone --name "example.com" --caller-reference "ref-001"` |
| List hosted zones | `awslocal route53 list-hosted-zones` |
| Get hosted zone | `awslocal route53 get-hosted-zone --id <zone-id>` |
| Delete hosted zone | `awslocal route53 delete-hosted-zone --id <zone-id>` |

### Record Set Operations
```bash
# Create / Update / Delete a record
awslocal route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "203.0.113.10"}]
      }
    }]
  }'

# List all records in a zone
awslocal route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

## Example Walkthrough

1. **Create a hosted zone for your domain**
   ```bash
   ZONE=$(awslocal route53 create-hosted-zone \
     --name "example-demo.local" \
     --caller-reference "ref-$(date +%s)" \
     --query 'HostedZone.Id' --output text)
   echo "Zone ID: $ZONE"
   ```
   Creates a new DNS zone that will hold all records for `example-demo.local`.

2. **Add an A record pointing to an application server**
   ```bash
   awslocal route53 change-resource-record-sets \
     --hosted-zone-id "$ZONE" \
     --change-batch '{
       "Changes": [{
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "app.example-demo.local",
           "Type": "A",
           "TTL": 300,
           "ResourceRecords": [{"Value": "10.0.0.1"}]
         }
       }]
     }'
   ```
   Maps `app.example-demo.local` to IP `10.0.0.1` with a 5-minute cache TTL.

3. **Add a CNAME so `www` resolves to `app`**
   ```bash
   awslocal route53 change-resource-record-sets \
     --hosted-zone-id "$ZONE" \
     --change-batch '{
       "Changes": [{
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "www.example-demo.local",
           "Type": "CNAME",
           "TTL": 60,
           "ResourceRecords": [{"Value": "app.example-demo.local"}]
         }
       }]
     }'
   ```
   Creates an alias so `www.example-demo.local` follows the A record for `app`.

4. **List all record sets in the zone**
   ```bash
   awslocal route53 list-resource-record-sets \
     --hosted-zone-id "$ZONE" \
     --output table
   ```
   Displays every DNS record currently configured in the zone.

5. **Update an A record to a new IP (e.g., after a deployment)**
   ```bash
   awslocal route53 change-resource-record-sets \
     --hosted-zone-id "$ZONE" \
     --change-batch '{
       "Changes": [{
         "Action": "UPSERT",
         "ResourceRecordSet": {
           "Name": "app.example-demo.local",
           "Type": "A",
           "TTL": 300,
           "ResourceRecords": [{"Value": "10.0.0.2"}]
         }
       }]
     }'
   ```
   `UPSERT` creates the record if it does not exist, or updates it if it does.

6. **Delete the hosted zone**
   ```bash
   awslocal route53 delete-hosted-zone --id "$ZONE"
   ```
   Removes the zone and all its records (all record sets must be deleted first in production).

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--name` | The domain name for the hosted zone (e.g., `example.com`) |
| `--caller-reference` | Unique string to prevent duplicate zone creation (use a timestamp) |
| `--hosted-zone-id` | ID of the zone to operate on (returned at creation) |
| `--change-batch` | JSON document describing one or more DNS record changes |
| `Action` (in change-batch) | `CREATE`, `DELETE`, or `UPSERT` for each record change |
| `TTL` | Cache duration in seconds (lower = faster propagation, higher = fewer DNS queries) |
| `--query` | JMESPath expression to filter/shape CLI output |
| `--output table` | Renders output as a human-readable ASCII table |

## How to Run the Demo
```bash
cd services/05-networking/route53
bash demo.sh
```

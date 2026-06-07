# AWS X-Ray

## What is it?
AWS X-Ray is a distributed tracing service that collects end-to-end request data as it flows through microservices, Lambda functions, databases, and external HTTP calls. You use it when a slow or failed request touches multiple services and you need to pinpoint exactly which component added latency or threw an error. Its main benefit is visualising the full call graph of a distributed application as a service map, with per-segment timing and annotation data, so you can identify bottlenecks and root causes in seconds instead of correlating logs manually across services.

## Key Concepts
- **Trace** — The complete record of a single request as it propagates through one or more services. Identified by a unique `Trace ID` in the format `1-<hex-epoch>-<hex-random>`.
- **Segment** — The data contributed by one service or resource for a single request (start time, end time, HTTP status, annotations, metadata). Each service creates one segment per request.
- **Subsegment** — A child unit within a segment representing a specific operation inside a service — a downstream HTTP call, a database query, or an internal function.
- **Annotation** — A key/value pair (string, number, or boolean) indexed by X-Ray so you can filter and group traces by it (e.g., `env=production`, `user_id=42`).
- **Metadata** — Arbitrary JSON attached to a segment or subsegment for debugging context. Unlike annotations, metadata is not indexed and cannot be used in filter expressions.
- **Sampling Rule** — A configuration that controls what fraction of incoming requests are traced. Reduces cost and noise in high-traffic services while keeping full visibility at low traffic.
- **Service Graph** — An automatically generated visual map showing every service and the connections between them, with aggregated latency and error rate per edge.

## When to Use
- Trace a slow API response across Lambda, DynamoDB, and an external payment service to find the bottleneck.
- Identify which downstream dependency is causing elevated error rates in a microservices architecture.
- Establish latency baselines and set up alerts when p99 latency degrades after a new deployment.
- Debug intermittent failures that only appear under load by reviewing sampled traces for error segments.

## CLI Quick Reference (awslocal)

### Submit a trace segment
```bash
TRACE_ID="1-$(printf '%08x' $(date +%s))-$(openssl rand -hex 12)"
SEGMENT_ID=$(openssl rand -hex 8)
START=$(date +%s)
awslocal xray put-trace-segments --trace-segment-documents "[
  {
    \"name\": \"my-service\",
    \"id\": \"${SEGMENT_ID}\",
    \"trace_id\": \"${TRACE_ID}\",
    \"start_time\": ${START}.0,
    \"end_time\": $((START+1)).0,
    \"in_progress\": false,
    \"http\": {\"response\": {\"status\": 200}}
  }
]"
```

### Get trace summaries (last 5 minutes)
```bash
awslocal xray get-trace-summaries \
  --start-time $(($(date +%s) - 300)) \
  --end-time $(date +%s)
```

### Get full trace by ID
```bash
awslocal xray batch-get-traces --trace-ids "1-5f84ab12-abcdef123456abcdef123456"
```

### Create a sampling rule
```bash
awslocal xray create-sampling-rule --sampling-rule '{
  "RuleName": "my-sampling-rule",
  "ResourceARN": "*",
  "Priority": 1000,
  "FixedRate": 0.05,
  "ReservoirSize": 5,
  "ServiceName": "my-service",
  "ServiceType": "*",
  "Host": "*",
  "HTTPMethod": "*",
  "URLPath": "*",
  "Version": 1
}'
```

### List sampling rules
```bash
awslocal xray get-sampling-rules
```

### Update a sampling rule
```bash
awslocal xray update-sampling-rule --sampling-rule-update '{
  "RuleName": "my-sampling-rule",
  "FixedRate": 0.10,
  "ReservoirSize": 10
}'
```

### Delete a sampling rule
```bash
awslocal xray delete-sampling-rule --rule-name "my-sampling-rule"
```

### Get the service graph
```bash
awslocal xray get-service-graph \
  --start-time $(($(date +%s) - 300)) \
  --end-time $(date +%s)
```

## Example Walkthrough

1. **Generate a unique Trace ID and Segment ID**
   ```bash
   TRACE_ID="1-$(printf '%08x' $(date +%s))-$(openssl rand -hex 12)"
   SEGMENT_ID=$(openssl rand -hex 8)
   START_TIME=$(date +%s)
   END_TIME=$((START_TIME + 1))
   ```
   The Trace ID format is required by X-Ray: `1-<8-hex-epoch-seconds>-<24-hex-random>`. The Segment ID is 16 hex characters.

2. **Submit a trace segment representing one service handling a request**
   ```bash
   awslocal xray put-trace-segments --trace-segment-documents "[
     {
       \"name\": \"demo-service\",
       \"id\": \"${SEGMENT_ID}\",
       \"trace_id\": \"${TRACE_ID}\",
       \"start_time\": ${START_TIME}.0,
       \"end_time\": ${END_TIME}.0,
       \"in_progress\": false,
       \"annotations\": {\"env\": \"demo\"},
       \"metadata\": {\"version\": \"1.0\"},
       \"http\": {\"response\": {\"status\": 200}}
     }
   ]"
   ```
   Sends the segment document to X-Ray. In production the X-Ray SDK or daemon does this automatically; here we do it manually to understand the data model.

3. **Retrieve trace summaries for the last 5 minutes**
   ```bash
   awslocal xray get-trace-summaries \
     --start-time $(($(date +%s) - 300)) \
     --end-time $(date +%s) \
     --query 'TraceSummaries[*].{Id:Id,Duration:Duration,ResponseTime:ResponseTime}' \
     --output table
   ```
   Returns a summary for each trace in the window: ID, total duration, and response time.

4. **Create a sampling rule to control what percentage of requests are traced**
   ```bash
   awslocal xray create-sampling-rule --sampling-rule "{
     \"RuleName\": \"demo-sampling-rule\",
     \"ResourceARN\": \"*\",
     \"Priority\": 1000,
     \"FixedRate\": 0.05,
     \"ReservoirSize\": 5,
     \"ServiceName\": \"demo-service\",
     \"ServiceType\": \"*\",
     \"Host\": \"*\",
     \"HTTPMethod\": \"*\",
     \"URLPath\": \"*\",
     \"Version\": 1
   }"
   ```
   Samples 5% of requests (`FixedRate: 0.05`) plus up to 5 requests per second regardless of rate (`ReservoirSize: 5`).

5. **List all sampling rules to confirm it was created**
   ```bash
   awslocal xray get-sampling-rules \
     --query 'SamplingRuleRecords[*].SamplingRule.{Name:RuleName,Rate:FixedRate,Priority:Priority}' \
     --output table
   ```
   Shows every rule with its name, fixed rate, and priority so you can verify the rule is in place.

6. **View the service graph to see connected services**
   ```bash
   awslocal xray get-service-graph \
     --start-time $(($(date +%s) - 300)) \
     --end-time $(date +%s) \
     --query 'Services[*].{Name:Name,Type:Type,State:State}' \
     --output table
   ```
   Returns the auto-generated map of services that appeared in traces during the time window, with their type and health state.

## Important Flags & Options

| Flag / Option | Command | Description |
|---|---|---|
| `--trace-segment-documents` | `put-trace-segments` | JSON array of segment document strings to ingest |
| `--trace-ids` | `batch-get-traces` | One or more trace IDs to fetch in full (segments + subsegments) |
| `--start-time` / `--end-time` | `get-trace-summaries`, `get-service-graph` | Unix epoch seconds defining the query window |
| `--filter-expression` | `get-trace-summaries` | X-Ray filter syntax to narrow results (e.g., `annotation.env = "production"`, `responsetime > 2`) |
| `--sampling` | `get-trace-summaries` | Sample a subset of traces when the result set is very large |
| `--sampling-rule` | `create-sampling-rule` | Full JSON object defining the rule name, rates, service matchers, and version |
| `--sampling-rule-update` | `update-sampling-rule` | Partial JSON object with only the fields to change (must include `RuleName`) |
| `--rule-name` | `delete-sampling-rule` | Name of the sampling rule to delete |
| `RuleName` (in rule JSON) | `create-sampling-rule` | Unique name for the rule |
| `FixedRate` (in rule JSON) | `create-sampling-rule` | Fraction of requests to sample after the reservoir is exhausted (0.0–1.0) |
| `ReservoirSize` (in rule JSON) | `create-sampling-rule` | Fixed number of requests per second to sample regardless of `FixedRate` |
| `Priority` (in rule JSON) | `create-sampling-rule` | Lower number = higher priority when multiple rules match (1–9999) |

## How to Run the Demo
```bash
cd services/07-monitoring/xray
bash demo.sh
```

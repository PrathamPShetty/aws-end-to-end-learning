# Amazon CloudWatch Logs

## What is it?
Amazon CloudWatch Logs is a fully managed log storage and analysis service that lets you ingest, store, search, and monitor log data from any source — applications, Lambda functions, EC2 instances, or containers. You use it when you need to centralise log output so it is durable, searchable, and can trigger alerts without managing your own log infrastructure. Its main benefit is tying log data directly into the broader CloudWatch ecosystem, so a single `ERROR` pattern in a log line can automatically publish a metric and fire an alarm.

## Key Concepts
- **Log Group** — The top-level organisational unit for logs, typically one per application or service (e.g., `/demo/app/logs`). Retention policies are set at this level.
- **Log Stream** — A sequence of log events from a single source within a log group (e.g., one EC2 instance, one Lambda invocation container).
- **Log Event** — A single record: a Unix timestamp (milliseconds) plus a message string.
- **Retention Policy** — How many days CloudWatch Logs keeps events before automatically deleting them (1 day to 10 years, or never expire).
- **Metric Filter** — A pattern-matching rule attached to a log group that converts matching log lines into a CloudWatch metric data point (e.g., count every line containing `ERROR`).
- **Filter Pattern** — The search expression used by metric filters and `filter-log-events` (e.g., `"ERROR"`, `[level="ERROR", ...]`).

## When to Use
- Centralise application logs from Lambda, ECS, EC2, or on-premises servers into one searchable store.
- Automatically count error or warning occurrences in logs and publish them as CloudWatch metrics to drive alarms.
- Retain audit logs for compliance without managing log rotation and archiving yourself.
- Perform ad-hoc log searches and tail live log streams during incident investigation.

## CLI Quick Reference (awslocal)

### Create a log group
```bash
awslocal logs create-log-group --log-group-name "/demo/app/logs"
```

### Set retention policy (days)
```bash
awslocal logs put-retention-policy \
  --log-group-name "/demo/app/logs" \
  --retention-in-days 30
```

### List log groups
```bash
awslocal logs describe-log-groups
```

### Create a log stream
```bash
awslocal logs create-log-stream \
  --log-group-name "/demo/app/logs" \
  --log-stream-name "demo-stream-001"
```

### List log streams
```bash
awslocal logs describe-log-streams --log-group-name "/demo/app/logs"
```

### Put log events
```bash
TIMESTAMP=$(date +%s%3N)
awslocal logs put-log-events \
  --log-group-name "/demo/app/logs" \
  --log-stream-name "demo-stream-001" \
  --log-events \
    timestamp=$TIMESTAMP,message="INFO: Application started" \
    timestamp=$((TIMESTAMP+1000)),message="ERROR: DB connection failed"
```

### Read log events
```bash
awslocal logs get-log-events \
  --log-group-name "/demo/app/logs" \
  --log-stream-name "demo-stream-001"
```

### Search across all streams in a group
```bash
awslocal logs filter-log-events \
  --log-group-name "/demo/app/logs" \
  --filter-pattern "ERROR"
```

### Create a metric filter
```bash
awslocal logs put-metric-filter \
  --log-group-name "/demo/app/logs" \
  --filter-name "demo-error-filter" \
  --filter-pattern "ERROR" \
  --metric-transformations \
    metricName=ErrorCount,metricNamespace=Demo/Logs,metricValue=1
```

### List metric filters
```bash
awslocal logs describe-metric-filters --log-group-name "/demo/app/logs"
```

### Delete a log group
```bash
awslocal logs delete-log-group --log-group-name "/demo/app/logs"
```

## Example Walkthrough

1. **Create a log group for your application**
   ```bash
   awslocal logs create-log-group --log-group-name "/demo/app/logs"
   ```
   Creates the top-level container where all log streams and retention settings for this application live.

2. **Create a log stream inside the group**
   ```bash
   awslocal logs create-log-stream \
     --log-group-name "/demo/app/logs" \
     --log-stream-name "demo-stream-001"
   ```
   Represents a single source of log events — in production this might be one Lambda container or one EC2 instance.

3. **Push log events into the stream**
   ```bash
   TIMESTAMP=$(date +%s%3N)
   awslocal logs put-log-events \
     --log-group-name "/demo/app/logs" \
     --log-stream-name "demo-stream-001" \
     --log-events \
       timestamp=$TIMESTAMP,message="INFO: Application started successfully" \
       timestamp=$((TIMESTAMP+1000)),message="ERROR: Failed to connect to database" \
       timestamp=$((TIMESTAMP+2000)),message="INFO: Retry successful, connected to database"
   ```
   Writes three log lines with millisecond timestamps; events must be in chronological order.

4. **Read back the log events**
   ```bash
   awslocal logs get-log-events \
     --log-group-name "/demo/app/logs" \
     --log-stream-name "demo-stream-001" \
     --query 'events[*].{Time:timestamp,Message:message}' \
     --output table
   ```
   Retrieves all stored events from the stream so you can confirm they were written correctly.

5. **Create a metric filter to count ERROR lines**
   ```bash
   awslocal logs put-metric-filter \
     --log-group-name "/demo/app/logs" \
     --filter-name "demo-error-filter" \
     --filter-pattern "ERROR" \
     --metric-transformations \
       metricName=ErrorCount,metricNamespace=Demo/Logs,metricValue=1
   ```
   Every future log event containing the word `ERROR` will increment the `ErrorCount` metric in the `Demo/Logs` namespace — ready to drive a CloudWatch alarm.

6. **Confirm the metric filter was registered**
   ```bash
   awslocal logs describe-metric-filters \
     --log-group-name "/demo/app/logs" \
     --query 'metricFilters[*].{Name:filterName,Pattern:filterPattern}' \
     --output table
   ```
   Lists all metric filters on the group so you can verify the filter name and pattern are correct.

## Important Flags & Options

| Flag / Option | Command | Description |
|---|---|---|
| `--log-group-name` | most commands | The log group to operate on (e.g., `/demo/app/logs`) |
| `--log-stream-name` | `create-log-stream`, `put-log-events`, `get-log-events` | The specific stream within a group |
| `--log-events` | `put-log-events` | Space-separated list of `timestamp=<ms>,message="<text>"` pairs |
| `--sequence-token` | `put-log-events` | Required for subsequent puts to an existing stream (use the token returned by the previous put) |
| `--retention-in-days` | `put-retention-policy` | Days to keep log events: `1`, `3`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1827`, `3653` |
| `--filter-pattern` | `put-metric-filter`, `filter-log-events` | Search expression to match log lines (e.g., `"ERROR"`, `[ip, user, timestamp, method="GET", ...]`) |
| `--metric-transformations` | `put-metric-filter` | Defines the target metric name, namespace, and value to emit when the pattern matches |
| `--start-time` / `--end-time` | `get-log-events`, `filter-log-events` | Restrict results to a time window (Unix epoch milliseconds) |
| `--limit` | `get-log-events`, `filter-log-events` | Maximum number of events to return per call |
| `--log-group-name-prefix` | `describe-log-groups` | Filter groups by name prefix for large accounts |

## How to Run the Demo
```bash
cd services/07-monitoring/cloudwatch-logs
bash demo.sh
```

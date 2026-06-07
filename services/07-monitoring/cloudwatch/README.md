# Amazon CloudWatch

## What is it?
Amazon CloudWatch is a monitoring and observability service that collects metrics, sets alarms, and visualizes operational data for AWS resources and custom applications. You use it when you need to track numerical performance data over time — such as CPU usage, request counts, or error rates — and respond automatically when values cross a threshold. Its main benefit is giving you a single pane of glass for operational health, with built-in alerting and dashboard capabilities so problems surface before they become outages.

## Key Concepts
- **Namespace** — A container that groups related metrics together (e.g., `AWS/EC2` or `Demo/App`). Keeps your custom metrics separate from AWS built-in metrics.
- **Metric** — A time-ordered set of data points identified by a namespace, metric name, and optional dimensions (e.g., `RequestCount` in `Demo/App`).
- **Dimension** — A name/value pair that further identifies a metric (e.g., `InstanceId=i-1234abcd`). Lets you filter metrics by resource.
- **Alarm** — Watches a single metric over a time period and triggers an action (notification, Auto Scaling, etc.) when a threshold is breached.
- **Dashboard** — A customizable console page with widgets that display metrics and alarms in real time.
- **Period** — The length of time (in seconds) over which a metric is aggregated for an alarm evaluation (e.g., `60` = 1 minute).

## When to Use
- Track application-level KPIs (request counts, latency, error rates) that AWS does not collect automatically.
- Alert on-call engineers via SNS when an error rate or queue depth exceeds a safe threshold.
- Build operational dashboards that show the health of multiple services side by side.
- Trigger Auto Scaling policies automatically when CPU or memory metrics cross defined limits.

## CLI Quick Reference (awslocal)

### Publish metrics
```bash
awslocal cloudwatch put-metric-data \
  --namespace "Demo/App" \
  --metric-name "RequestCount" \
  --value 150 \
  --unit Count
```

### List metrics
```bash
awslocal cloudwatch list-metrics --namespace "Demo/App"
```

### Get metric statistics
```bash
awslocal cloudwatch get-metric-statistics \
  --namespace "Demo/App" \
  --metric-name "RequestCount" \
  --start-time 2026-06-07T00:00:00Z \
  --end-time   2026-06-07T23:59:59Z \
  --period 300 \
  --statistics Sum
```

### Create / update an alarm
```bash
awslocal cloudwatch put-metric-alarm \
  --alarm-name "high-request-alarm" \
  --namespace "Demo/App" \
  --metric-name "RequestCount" \
  --statistic Sum \
  --period 60 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### Describe alarms
```bash
awslocal cloudwatch describe-alarms --alarm-names "high-request-alarm"
```

### Delete an alarm
```bash
awslocal cloudwatch delete-alarms --alarm-names "high-request-alarm"
```

### Create a dashboard
```bash
awslocal cloudwatch put-dashboard \
  --dashboard-name "app-dashboard" \
  --dashboard-body '{"widgets":[{"type":"metric","properties":{"metrics":[["Demo/App","RequestCount"]],"period":60,"title":"Request Count"}}]}'
```

### List dashboards
```bash
awslocal cloudwatch list-dashboards
```

### Delete a dashboard
```bash
awslocal cloudwatch delete-dashboards --dashboard-names "app-dashboard"
```

## Example Walkthrough

1. **Publish two data points for a custom metric**
   ```bash
   awslocal cloudwatch put-metric-data --namespace "Demo/App" --metric-name "RequestCount" --value 150 --unit Count
   awslocal cloudwatch put-metric-data --namespace "Demo/App" --metric-name "RequestCount" --value 320 --unit Count
   ```
   Sends two numeric readings into the `Demo/App` namespace so CloudWatch has data to work with.

2. **Confirm the metric was recorded**
   ```bash
   awslocal cloudwatch list-metrics --namespace "Demo/App" --output table
   ```
   Lists every metric in the namespace; you should see `RequestCount` appear.

3. **Create an alarm that fires when RequestCount exceeds 200**
   ```bash
   awslocal cloudwatch put-metric-alarm \
     --alarm-name "demo-high-request-alarm" \
     --namespace "Demo/App" \
     --metric-name "RequestCount" \
     --statistic Sum \
     --period 60 \
     --threshold 200 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 1 \
     --alarm-description "Alarm when RequestCount exceeds 200"
   ```
   Creates an alarm that evaluates the 1-minute sum and transitions to `ALARM` state when it exceeds 200.

4. **Check the current alarm state**
   ```bash
   awslocal cloudwatch describe-alarms \
     --alarm-names "demo-high-request-alarm" \
     --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue,Threshold:Threshold}' \
     --output table
   ```
   Shows the alarm name, its current state (`OK`, `ALARM`, or `INSUFFICIENT_DATA`), and the threshold.

5. **Create a dashboard to visualise the metric**
   ```bash
   awslocal cloudwatch put-dashboard \
     --dashboard-name "demo-dashboard" \
     --dashboard-body '{"widgets":[{"type":"metric","properties":{"metrics":[["Demo/App","RequestCount"]],"period":60,"title":"Request Count"}}]}'
   ```
   Saves a dashboard definition with one metric widget for `RequestCount`.

6. **Verify the dashboard was saved**
   ```bash
   awslocal cloudwatch list-dashboards \
     --query 'DashboardEntries[*].{Name:DashboardName}' \
     --output table
   ```
   Confirms `demo-dashboard` is listed and ready to view.

## Important Flags & Options

| Flag / Option | Command | Description |
|---|---|---|
| `--namespace` | `put-metric-data`, `list-metrics` | Groups metrics logically (e.g., `Demo/App`, `AWS/EC2`) |
| `--metric-name` | `put-metric-data`, `put-metric-alarm` | Name of the specific metric (e.g., `RequestCount`) |
| `--value` | `put-metric-data` | The numeric data point to publish |
| `--unit` | `put-metric-data` | Unit for the value: `Count`, `Bytes`, `Seconds`, `Percent`, etc. |
| `--statistic` | `put-metric-alarm`, `get-metric-statistics` | Aggregation function: `Sum`, `Average`, `Maximum`, `Minimum`, `SampleCount` |
| `--period` | `put-metric-alarm`, `get-metric-statistics` | Aggregation window in seconds (minimum `60`) |
| `--threshold` | `put-metric-alarm` | The value that triggers the alarm when crossed |
| `--comparison-operator` | `put-metric-alarm` | How to compare metric vs threshold: `GreaterThanThreshold`, `LessThanThreshold`, etc. |
| `--evaluation-periods` | `put-metric-alarm` | Number of consecutive periods the metric must breach before the alarm fires |
| `--alarm-description` | `put-metric-alarm` | Human-readable description shown in the console and notifications |
| `--dashboard-body` | `put-dashboard` | JSON string defining the dashboard layout and widgets |

## How to Run the Demo
```bash
cd services/07-monitoring/cloudwatch
bash demo.sh
```

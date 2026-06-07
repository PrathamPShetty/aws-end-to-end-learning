#!/bin/bash
# ============================================================
# CloudWatch Demo — Custom Metrics, Alarms, and Dashboards
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

NAMESPACE="Demo/App"
METRIC="RequestCount"
ALARM="demo-high-request-alarm"
DASHBOARD="demo-dashboard"

echo "==> Putting custom metric data points..."
awslocal cloudwatch put-metric-data --namespace "$NAMESPACE" --metric-name "$METRIC" --value 150 --unit Count
awslocal cloudwatch put-metric-data --namespace "$NAMESPACE" --metric-name "$METRIC" --value 320 --unit Count

echo "==> Listing metrics in namespace $NAMESPACE..."
awslocal cloudwatch list-metrics \
  --namespace "$NAMESPACE" \
  --query 'Metrics[*].{Namespace:Namespace,MetricName:MetricName}' \
  --output table

echo "==> Creating alarm: $ALARM..."
awslocal cloudwatch put-metric-alarm \
  --alarm-name "$ALARM" \
  --namespace "$NAMESPACE" \
  --metric-name "$METRIC" \
  --statistic Sum \
  --period 60 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-description "Alarm when RequestCount exceeds 200" || true

echo "==> Describing alarm state..."
awslocal cloudwatch describe-alarms \
  --alarm-names "$ALARM" \
  --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue,Threshold:Threshold}' \
  --output table

echo "==> Creating dashboard and listing dashboards..."
DASH_BODY='{"widgets":[{"type":"metric","properties":{"metrics":[["Demo/App","RequestCount"]],"period":60,"title":"Request Count"}}]}'
awslocal cloudwatch put-dashboard --dashboard-name "$DASHBOARD" --dashboard-body "$DASH_BODY" || true
awslocal cloudwatch list-dashboards --query 'DashboardEntries[*].{Name:DashboardName}' --output table

echo "==> CloudWatch demo complete."

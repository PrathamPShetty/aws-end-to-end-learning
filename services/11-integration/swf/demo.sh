#!/bin/bash
# ============================================================
# SWF (Simple Workflow Service) Demo
# Purpose: Register domain, workflow type, activity, start execution
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

DOMAIN="demo-workflow-domain"
WORKFLOW_NAME="OrderFulfillment"
WORKFLOW_VERSION="1.0"
ACTIVITY_NAME="ProcessOrder"
ACTIVITY_VERSION="1.0"
TASK_LIST="demo-tasklist"

echo "==> Registering SWF domain..."
awslocal swf register-domain --name "$DOMAIN" \
  --workflow-execution-retention-period-in-days 7 \
  --description "Demo order fulfillment domain" 2>/dev/null || true
echo "  Domain: $DOMAIN"

echo "==> Registering workflow type..."
awslocal swf register-workflow-type --domain "$DOMAIN" \
  --name "$WORKFLOW_NAME" --workflow-version "$WORKFLOW_VERSION" \
  --default-task-list "name=$TASK_LIST" \
  --default-execution-start-to-close-timeout 3600 \
  --default-task-start-to-close-timeout 300 2>/dev/null || true
echo "  Workflow: $WORKFLOW_NAME v$WORKFLOW_VERSION"

echo "==> Registering activity type..."
awslocal swf register-activity-type --domain "$DOMAIN" \
  --name "$ACTIVITY_NAME" --activity-version "$ACTIVITY_VERSION" \
  --default-task-list "name=$TASK_LIST" \
  --default-task-schedule-to-close-timeout 600 \
  --default-task-start-to-close-timeout 300 2>/dev/null || true
echo "  Activity: $ACTIVITY_NAME v$ACTIVITY_VERSION"

echo "==> Starting workflow execution..."
RUN_ID=$(awslocal swf start-workflow-execution \
  --domain "$DOMAIN" --workflow-id "order-exec-$(date +%s)" \
  --workflow-type "name=$WORKFLOW_NAME,version=$WORKFLOW_VERSION" \
  --task-list "name=$TASK_LIST" \
  --input '{"orderId":"ORD-007","items":[{"sku":"ITEM-1","qty":2}]}' \
  --execution-start-to-close-timeout 3600 \
  --output text --query 'runId')
echo "  Run ID: $RUN_ID"

echo "==> Open workflow executions..."
awslocal swf list-open-workflow-executions --domain "$DOMAIN" --oldest-date 1 \
  --query 'executionInfos[].{WorkflowId:execution.workflowId,Status:executionStatus}' --output table

echo "==> Registered workflow types..."
awslocal swf list-workflow-types --domain "$DOMAIN" --registration-status REGISTERED \
  --query 'typeInfos[].{Name:workflowType.name,Version:workflowType.version}' --output table

echo "==> SWF demo complete."

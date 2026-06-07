#!/bin/bash
# ============================================================
# AWS IoT Core Demo
# Purpose: Create thing, attach certificate+policy, publish message
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

THING_NAME="demo-temperature-sensor"
POLICY_NAME="demo-iot-policy"

echo "==> Creating IoT thing type..."
awslocal iot create-thing-type --thing-type-name "TemperatureSensor" \
  --thing-type-properties "thingTypeDescription=Demo sensor type" \
  > /dev/null 2>&1 || true

echo "==> Creating IoT thing..."
awslocal iot create-thing --thing-name "$THING_NAME" \
  --thing-type-name "TemperatureSensor" \
  --attribute-payload '{"attributes":{"location":"building-A","floor":"3"}}' \
  > /dev/null 2>&1 || true
echo "  Thing: $THING_NAME"

echo "==> Creating IoT policy..."
awslocal iot create-policy --policy-name "$POLICY_NAME" \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["iot:Publish","iot:Subscribe","iot:Connect","iot:Receive"],"Resource":"*"}]}' \
  > /dev/null 2>&1 || true
echo "  Policy: $POLICY_NAME"

echo "==> Creating certificate and attaching to thing+policy..."
CERT_ARN=$(awslocal iot create-keys-and-certificate --set-as-active \
  --output text --query 'certificateArn' 2>/dev/null || echo "")
if [ -n "$CERT_ARN" ]; then
  awslocal iot attach-policy --policy-name "$POLICY_NAME" --target "$CERT_ARN" || true
  awslocal iot attach-thing-principal --thing-name "$THING_NAME" --principal "$CERT_ARN" || true
  echo "  Certificate attached: ${CERT_ARN##*/}"
fi

echo "==> Publishing telemetry to IoT topic..."
awslocal iot-data publish \
  --topic "sensors/$THING_NAME/temperature" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"temp":22.5,"unit":"C","deviceId":"demo-temp-sensor"}' \
  > /dev/null 2>&1 || true
echo "  Published to: sensors/$THING_NAME/temperature"

echo "==> Thing details..."
awslocal iot describe-thing --thing-name "$THING_NAME" \
  --query '{Name:thingName,Type:thingTypeName,Attributes:attributes}' --output table

echo "==> Listing things..."
awslocal iot list-things \
  --query 'things[].{Name:thingName,Type:thingTypeName}' --output table

echo "==> IoT Core demo complete."

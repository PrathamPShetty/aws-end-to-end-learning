#!/bin/bash
# ============================================================
# AWS IoT Core Demo
# Purpose: Create thing, attach policy, publish MQTT messages
# ============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

THING_NAME="demo-temperature-sensor"
POLICY_NAME="demo-iot-policy"
THING_TYPE="TemperatureSensor"

echo "==> Creating IoT thing type..."
awslocal iot create-thing-type \
  --thing-type-name "$THING_TYPE" \
  --thing-type-properties "thingTypeDescription=A demo temperature sensor type" \
  > /dev/null 2>&1 || true
echo "  Thing type: $THING_TYPE"

echo "==> Creating IoT thing..."
THING_ARN=$(awslocal iot create-thing \
  --thing-name "$THING_NAME" \
  --thing-type-name "$THING_TYPE" \
  --attribute-payload '{"attributes":{"location":"building-A","floor":"3"}}' \
  --output text --query 'thingArn') 2>/dev/null || \
THING_ARN=$(awslocal iot describe-thing \
  --thing-name "$THING_NAME" \
  --output text --query 'thingArn')
echo "  Thing ARN: $THING_ARN"

echo "==> Creating IoT policy..."
awslocal iot create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["iot:Publish","iot:Subscribe","iot:Connect","iot:Receive"],
      "Resource": "*"
    }]
  }' > /dev/null 2>&1 || true
echo "  Policy: $POLICY_NAME"

echo "==> Creating certificate and attaching to thing..."
CERT_OUTPUT=$(awslocal iot create-keys-and-certificate --set-as-active 2>/dev/null || echo '{}')
CERT_ARN=$(echo "$CERT_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('certificateArn',''))" 2>/dev/null || true)

if [ -n "$CERT_ARN" ]; then
  awslocal iot attach-policy --policy-name "$POLICY_NAME" --target "$CERT_ARN" || true
  awslocal iot attach-thing-principal --thing-name "$THING_NAME" --principal "$CERT_ARN" || true
  echo "  Certificate attached: ${CERT_ARN##*/}"
fi

echo "==> Publishing to IoT topic via HTTP endpoint..."
awslocal iot-data publish \
  --topic "sensors/$THING_NAME/temperature" \
  --payload '{"deviceId":"demo-temp-sensor","temp":22.5,"unit":"C","timestamp":1700000000}' \
  --cli-binary-format raw-in-base64-out \
  > /dev/null 2>&1 || \
awslocal iot-data publish \
  --topic "sensors/$THING_NAME/temperature" \
  --payload "$(echo '{"deviceId":"demo-temp-sensor","temp":22.5}' | base64)" \
  > /dev/null 2>&1 || true
echo "  Published temperature reading to topic"

echo "==> Describing thing..."
awslocal iot describe-thing \
  --thing-name "$THING_NAME" \
  --query '{Name:thingName,Type:thingTypeName,Attributes:attributes}' \
  --output table

echo "==> Listing things..."
awslocal iot list-things \
  --query 'things[].{Name:thingName,Type:thingTypeName}' \
  --output table

echo "==> IoT Core demo complete."

# AWS IoT Core

## What is it?
AWS IoT Core is a fully managed cloud platform that lets you connect billions of IoT devices to AWS services without provisioning or managing infrastructure. Devices communicate over MQTT, HTTPS, or WebSockets; IoT Core authenticates them with X.509 certificates and routes their messages through a built-in rules engine to downstream services like Lambda, DynamoDB, S3, or SNS. It also maintains a persistent Device Shadow — a JSON document representing each device's last-known and desired state — so cloud applications can interact with devices even when they are offline. IoT Core is the right choice whenever you need secure, scalable, bidirectional communication between physical devices and the cloud.

## Key Concepts
- **Thing** — a logical representation of a physical device or entity registered in the IoT Core Thing Registry, with optional attributes and a type.
- **Certificate** — an X.509 certificate that authenticates a device to IoT Core; created with `create-keys-and-certificate` and must be activated before use.
- **Policy** — an IoT policy (similar to IAM) attached to a certificate that controls which MQTT topics the device can publish, subscribe to, and connect on.
- **Topic** — an MQTT topic string (e.g., `sensors/device-001/temperature`) used to route messages from devices to rules and to other subscribers.
- **Rules Engine** — evaluates SQL-like queries against incoming messages and forwards matching messages to configured AWS service actions (Lambda, DynamoDB, S3, etc.).
- **Device Shadow** — a JSON document stored in IoT Core that holds the `reported` state (last sent by device) and `desired` state (set by cloud apps), with a `delta` section showing differences.

## When to Use
- **Industrial sensor telemetry** — collect temperature, pressure, and vibration readings from factory floor sensors, route them to Timestream or DynamoDB via the rules engine.
- **Smart home devices** — manage device state through Device Shadows so a mobile app can read or change settings even when the physical device is temporarily offline.
- **Fleet management** — track GPS coordinates, fuel levels, and engine diagnostics from thousands of vehicles; trigger Lambda alerts on anomalous readings.
- **Remote device configuration** — push firmware update instructions or parameter changes to devices by writing to their Device Shadow desired state, and let devices acknowledge by updating reported state.

## CLI Quick Reference (awslocal)

### Create a thing type
```bash
awslocal iot create-thing-type \
  --thing-type-name TemperatureSensor \
  --thing-type-properties "thingTypeDescription=Sensor that reports temperature"
```

### Create a thing
```bash
awslocal iot create-thing \
  --thing-name device-001 \
  --thing-type-name TemperatureSensor \
  --attribute-payload '{"attributes":{"location":"building-A","floor":"3"}}'
```

### List things
```bash
awslocal iot list-things \
  --query 'things[].{Name:thingName,Type:thingTypeName,Attributes:attributes}' \
  --output table
```

### Describe a thing
```bash
awslocal iot describe-thing --thing-name device-001
```

### Create a policy
```bash
awslocal iot create-policy \
  --policy-name device-publish-policy \
  --policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Action":["iot:Publish","iot:Subscribe","iot:Connect","iot:Receive"],
      "Resource":"*"
    }]
  }'
```

### Create a certificate
```bash
awslocal iot create-keys-and-certificate --set-as-active
```

### Attach policy to certificate
```bash
awslocal iot attach-policy \
  --policy-name device-publish-policy \
  --target arn:aws:iot:us-east-1:000000000000:cert/abc123...
```

### Attach certificate to thing
```bash
awslocal iot attach-thing-principal \
  --thing-name device-001 \
  --principal arn:aws:iot:us-east-1:000000000000:cert/abc123...
```

### Publish a message
```bash
awslocal iot-data publish \
  --topic "sensors/device-001/temperature" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"temp":22.5,"unit":"C"}'
```

### Delete a thing
```bash
awslocal iot delete-thing --thing-name device-001
```

## Example Walkthrough

1. **Create a thing type** — define a reusable category for all temperature sensors.
   ```bash
   awslocal iot create-thing-type \
     --thing-type-name TemperatureSensor \
     --thing-type-properties "thingTypeDescription=Demo sensor type"
   ```

2. **Register a thing** — add device-001 to the registry with location attributes.
   ```bash
   awslocal iot create-thing \
     --thing-name device-001 \
     --thing-type-name TemperatureSensor \
     --attribute-payload '{"attributes":{"location":"building-A","floor":"3"}}'
   ```

3. **Create an IoT policy** — allow the device to publish, subscribe, and receive on any topic.
   ```bash
   awslocal iot create-policy \
     --policy-name device-publish-policy \
     --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["iot:Publish","iot:Subscribe","iot:Connect","iot:Receive"],"Resource":"*"}]}'
   ```

4. **Create a certificate and activate it** — generates the device's identity credentials.
   ```bash
   CERT_ARN=$(awslocal iot create-keys-and-certificate --set-as-active \
     --output text --query 'certificateArn')
   echo "Certificate ARN: $CERT_ARN"
   ```

5. **Attach the policy and thing to the certificate** — link identity, permissions, and device together.
   ```bash
   awslocal iot attach-policy \
     --policy-name device-publish-policy \
     --target "$CERT_ARN"
   awslocal iot attach-thing-principal \
     --thing-name device-001 \
     --principal "$CERT_ARN"
   ```

6. **Publish a telemetry message** — simulate the device sending a temperature reading.
   ```bash
   awslocal iot-data publish \
     --topic "sensors/device-001/temperature" \
     --cli-binary-format raw-in-base64-out \
     --payload '{"temp":22.5,"unit":"C","deviceId":"device-001"}'
   echo "Message published to sensors/device-001/temperature"
   ```

7. **Describe the thing** — confirm the registry entry with its attributes.
   ```bash
   awslocal iot describe-thing --thing-name device-001 \
     --query '{Name:thingName,Type:thingTypeName,Attributes:attributes}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--thing-name` | Unique identifier for the device in the registry | `device-001` |
| `--thing-type-name` | Category/type to assign to the thing | `TemperatureSensor` |
| `--attribute-payload` | Key-value metadata attached to the thing | `'{"attributes":{"loc":"A"}}'` |
| `--policy-name` | Name of the IoT policy being created or referenced | `device-publish-policy` |
| `--policy-document` | JSON IoT policy defining allowed actions/resources | See create-policy example |
| `--set-as-active` | Immediately activate the certificate after creation | (flag only) |
| `--target` | ARN of a certificate or thing group to attach a policy to | `arn:aws:iot:...:cert/...` |
| `--principal` | ARN of the certificate to attach to a thing | `arn:aws:iot:...:cert/...` |
| `--topic` | MQTT topic string for `iot-data publish` | `sensors/device-001/temp` |
| `--cli-binary-format` | Required when passing raw JSON as `--payload` | `raw-in-base64-out` |
| `--payload` | Message body to publish to the topic | `'{"temp":22.5}'` |

## How to Run the Demo

```bash
cd services/11-integration/iot
bash demo.sh
```

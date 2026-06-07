# AWS AppConfig

## What is it?
AWS AppConfig is a feature of AWS Systems Manager that lets you create, manage, and safely deploy application configuration data separately from your application code. It is purpose-built for scenarios where you need to roll out a configuration change gradually — for example, enabling a feature flag for 10% of users before expanding to 100% — without redeploying your application. AppConfig supports validators to catch bad configuration before it reaches production, and it tracks deployment history so you can roll back instantly if something goes wrong. Its main benefit is that it decouples configuration changes from code deployments, allowing operations teams to tune application behaviour in real time.

## Key Concepts
- **Application** — The top-level logical container in AppConfig. An Application groups together all environments and configuration profiles for one service or workload.
- **Environment** — A deployment target such as `production`, `staging`, or `dev`. Each environment independently tracks which version of a configuration is currently active.
- **Configuration Profile** — Defines where the configuration data lives (hosted inside AppConfig or in an external source like S3 or SSM Parameter Store) and what validator to apply to it.
- **Hosted Configuration Version** — A specific snapshot of configuration content stored directly in AppConfig. Each update creates a new immutable version number.
- **Deployment Strategy** — Controls how a configuration rolls out: the total duration, bake time, and growth factor (what percentage of the fleet receives the new config per interval).
- **Deployment** — An active rollout of a specific configuration version to an environment using a chosen deployment strategy.

## When to Use
- **Feature flag management** — Enable or disable features at runtime without redeploying; gradually roll out a new UI to a percentage of users and monitor for errors before full release.
- **Operational tuning** — Change connection pool sizes, timeout values, or rate-limit thresholds in a live production service without a code deployment.
- **Safe configuration rollouts** — Use a deployment strategy with bake time and growth factor to catch bad configuration early in the rollout and trigger an automatic rollback before all users are affected.
- **Multi-environment config management** — Maintain separate `dev`, `staging`, and `prod` configuration values under the same Application, with independent deployment histories per environment.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create an application | `awslocal appconfig create-application --name my-app` |
| List applications | `awslocal appconfig list-applications` |
| Create an environment | `awslocal appconfig create-environment --application-id APP_ID --name production` |
| Create a config profile | `awslocal appconfig create-configuration-profile --application-id APP_ID --name my-profile --location-uri hosted` |
| Upload a config version | `awslocal appconfig create-hosted-configuration-version --application-id APP_ID --configuration-profile-id PROFILE_ID --content '{"flag":true}' --content-type application/json` |
| Create a deployment strategy | `awslocal appconfig create-deployment-strategy --name instant --deployment-duration-in-minutes 0 --growth-factor 100 --replicate-to NONE` |
| Start a deployment | `awslocal appconfig start-deployment --application-id APP_ID --environment-id ENV_ID --deployment-strategy-id STRATEGY_ID --configuration-profile-id PROFILE_ID --configuration-version 1` |
| List config profiles | `awslocal appconfig list-configuration-profiles --application-id APP_ID` |
| List deployments | `awslocal appconfig list-deployments --application-id APP_ID --environment-id ENV_ID` |

## Example Walkthrough

1. **Create an AppConfig application** — Register the top-level container for your service's configuration.
   ```bash
   APP_ID=$(awslocal appconfig create-application \
     --name "demo-app" \
     --description "Demo application" \
     --query 'Id' --output text)
   echo "Application ID: $APP_ID"
   ```

2. **Create an environment** — Define the `demo-env` deployment target.
   ```bash
   ENV_ID=$(awslocal appconfig create-environment \
     --application-id "$APP_ID" \
     --name "demo-env" \
     --query 'Id' --output text)
   ```

3. **Create a configuration profile** — Tell AppConfig that config data will be stored as hosted content.
   ```bash
   PROFILE_ID=$(awslocal appconfig create-configuration-profile \
     --application-id "$APP_ID" \
     --name "demo-profile" \
     --location-uri "hosted" \
     --query 'Id' --output text)
   ```

4. **Upload a hosted configuration version** — Store a JSON feature-flag document as version 1.
   ```bash
   VERSION=$(awslocal appconfig create-hosted-configuration-version \
     --application-id "$APP_ID" \
     --configuration-profile-id "$PROFILE_ID" \
     --content '{"feature_dark_mode":true,"max_retries":3}' \
     --content-type "application/json" \
     --query 'VersionNumber' --output text)
   echo "Config version: $VERSION"
   ```

5. **Create an instant deployment strategy** — Define a strategy that deploys immediately with 100% rollout.
   ```bash
   STRATEGY_ID=$(awslocal appconfig create-deployment-strategy \
     --name "demo-instant" \
     --deployment-duration-in-minutes 0 \
     --growth-factor 100 \
     --replicate-to "NONE" \
     --query 'Id' --output text)
   ```

6. **Start the deployment** — Push the new config version to the environment.
   ```bash
   awslocal appconfig start-deployment \
     --application-id "$APP_ID" \
     --environment-id "$ENV_ID" \
     --deployment-strategy-id "$STRATEGY_ID" \
     --configuration-profile-id "$PROFILE_ID" \
     --configuration-version "$VERSION" \
     --query '{State:State,PercentageComplete:PercentageComplete}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description |
|---------------|-------------|
| `--application-id` | The ID of the AppConfig Application resource (returned when the application is created). |
| `--environment-id` | The ID of the target environment for a deployment. |
| `--configuration-profile-id` | The ID of the configuration profile that points to the config data source. |
| `--location-uri` | Where config data lives. Use `hosted` for AppConfig-managed storage, or an S3/SSM URI for external sources. |
| `--content` | The raw configuration content to upload (JSON, YAML, or plain text). |
| `--content-type` | MIME type of the content, e.g. `application/json` or `application/x-yaml`. |
| `--deployment-duration-in-minutes` | Total time for the rollout. Set to `0` for an instant deployment. |
| `--growth-factor` | Percentage of the fleet to update per interval during a gradual rollout (1–100). |
| `--replicate-to` | Whether to replicate the deployment strategy to other regions. Use `NONE` for local-only. |
| `--configuration-version` | The version number of the hosted configuration to deploy. |

## How to Run the Demo
```bash
cd services/08-management/appconfig
bash demo.sh
```

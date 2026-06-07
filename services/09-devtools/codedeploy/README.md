# AWS CodeDeploy

## What is it?
AWS CodeDeploy is a fully managed deployment service that automates the release of application revisions to EC2 instances, on-premises servers, AWS Lambda functions, or Amazon ECS services. Instead of writing custom deployment scripts, you describe your deployment strategy in an `AppSpec` file and CodeDeploy handles the rollout, health checks, and automatic rollback if something goes wrong. It supports multiple traffic-shifting strategies — all-at-once, half-at-a-time, one-at-a-time, and canary — so you can choose the right balance of speed and safety for each application. CodeDeploy is the deployment engine most commonly used as the final stage in a CodePipeline.

## Key Concepts
- **Application** — a named container that groups all deployment resources (deployment groups, revisions, and deployments) for a single software project.
- **Deployment Group** — a set of target instances or a Lambda/ECS resource, together with the deployment configuration and lifecycle hooks, that belongs to one application.
- **Revision** — the deployable artifact (an S3 zip, a GitHub commit, or an ECR image) that CodeDeploy copies to target instances.
- **AppSpec File** — a YAML or JSON file (`appspec.yml`) included in the revision that tells CodeDeploy where to copy files and which lifecycle hook scripts to run.
- **Deployment Configuration** — a named rule that controls how many targets receive the new revision at a time (e.g. `CodeDeployDefault.AllAtOnce`, `CodeDeployDefault.HalfAtATime`).
- **Lifecycle Event Hooks** — named points in the deployment process (`BeforeInstall`, `AfterInstall`, `ApplicationStart`, `ValidateService`) where you can run custom scripts.

## When to Use
- **Zero-downtime rolling deployments** — use `CodeDeployDefault.OneAtATime` to update a fleet of EC2 instances one by one so the application stays available throughout the rollout.
- **Blue/green deployments** — spin up a new set of instances with the new version, route traffic over, then terminate the old set; CodeDeploy automates the entire swap.
- **Lambda canary releases** — shift a small percentage of traffic to a new Lambda version first, monitor alarms, and either complete or roll back the shift automatically.
- **Automated rollback on failure** — attach a CloudWatch alarm to the deployment group so CodeDeploy reverts to the previous revision if error rates spike during deployment.

## CLI Quick Reference (awslocal)

### Create application
```bash
awslocal codedeploy create-application \
  --application-name my-app \
  --compute-platform Server
```

### List applications
```bash
awslocal codedeploy list-applications \
  --query 'applications' \
  --output table
```

### Get application details
```bash
awslocal codedeploy get-application \
  --application-name my-app
```

### Create deployment group
```bash
awslocal codedeploy create-deployment-group \
  --application-name my-app \
  --deployment-group-name my-dg \
  --service-role-arn arn:aws:iam::000000000000:role/codedeploy-role \
  --deployment-config-name CodeDeployDefault.AllAtOnce \
  --ec2-tag-filters Key=Env,Value=prod,Type=KEY_AND_VALUE
```

### Create a deployment
```bash
awslocal codedeploy create-deployment \
  --application-name my-app \
  --deployment-group-name my-dg \
  --revision '{"revisionType":"S3","s3Location":{"bucket":"my-deploy-bucket","key":"bundle.zip","bundleType":"zip"}}' \
  --query 'deploymentId' --output text
```

### Get deployment status
```bash
awslocal codedeploy get-deployment \
  --deployment-id d-XXXXXXXXX \
  --query 'deploymentInfo.{Id:deploymentId,Status:status,Config:deploymentConfigName}' \
  --output table
```

### List deployments
```bash
awslocal codedeploy list-deployments \
  --application-name my-app \
  --deployment-group-name my-dg \
  --query 'deployments' \
  --output table
```

### Delete application
```bash
awslocal codedeploy delete-application --application-name my-app
```

## Example Walkthrough

1. **Create the IAM service role** — CodeDeploy assumes this role to interact with EC2, S3, and other services on your behalf.
   ```bash
   awslocal iam create-role \
     --role-name codedeploy-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codedeploy.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Create an S3 bucket for the deployment bundle** — the revision (your zipped application code and AppSpec) is stored here.
   ```bash
   awslocal s3api create-bucket --bucket my-deploy-bucket
   ```

3. **Create the CodeDeploy application** — register a named application using the `Server` compute platform.
   ```bash
   awslocal codedeploy create-application \
     --application-name hello-app \
     --compute-platform Server \
     --query 'applicationId' --output text
   ```

4. **Create a deployment group** — define the target instances (by EC2 tag), the IAM role, and the deployment configuration.
   ```bash
   awslocal codedeploy create-deployment-group \
     --application-name hello-app \
     --deployment-group-name prod-servers \
     --service-role-arn "arn:aws:iam::000000000000:role/codedeploy-role" \
     --deployment-config-name CodeDeployDefault.AllAtOnce \
     --ec2-tag-filters Key=Env,Value=prod,Type=KEY_AND_VALUE \
     --query 'deploymentGroupId' --output text
   ```

5. **Create a deployment** — point CodeDeploy at the S3 bundle and start the rollout.
   ```bash
   DEPLOY_ID=$(awslocal codedeploy create-deployment \
     --application-name hello-app \
     --deployment-group-name prod-servers \
     --revision '{"revisionType":"S3","s3Location":{"bucket":"my-deploy-bucket","key":"bundle.zip","bundleType":"zip"}}' \
     --query 'deploymentId' --output text)
   echo "Deployment: $DEPLOY_ID"
   ```

6. **Check deployment status** — inspect the status and configuration of the running deployment.
   ```bash
   awslocal codedeploy get-deployment \
     --deployment-id "$DEPLOY_ID" \
     --query 'deploymentInfo.{Id:deploymentId,Status:status,App:applicationName,Group:deploymentGroupName}' \
     --output table
   ```

7. **List all deployments** — view every deployment that ran against the deployment group.
   ```bash
   awslocal codedeploy list-deployments \
     --application-name hello-app \
     --deployment-group-name prod-servers \
     --query 'deployments' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--application-name` | Name of the CodeDeploy application | `hello-app` |
| `--compute-platform` | Target platform type: `Server`, `Lambda`, or `ECS` | `Server` |
| `--deployment-group-name` | Name of the deployment group within the application | `prod-servers` |
| `--service-role-arn` | IAM role ARN that CodeDeploy assumes during deployments | `arn:aws:iam::000000000000:role/codedeploy-role` |
| `--deployment-config-name` | Traffic-shifting strategy to apply | `CodeDeployDefault.AllAtOnce`, `CodeDeployDefault.OneAtATime` |
| `--ec2-tag-filters` | EC2 instance tags that identify the target fleet | `Key=Env,Value=prod,Type=KEY_AND_VALUE` |
| `--revision` | JSON describing the artifact location (S3, GitHub, or AppSpec) | `'{"revisionType":"S3","s3Location":{...}}'` |
| `--deployment-id` | Unique identifier of a specific deployment | `d-A1B2C3D4E` |
| `--auto-rollback-configuration` | Enable automatic rollback on deployment failure or alarm | `'{"enabled":true,"events":["DEPLOYMENT_FAILURE"]}'` |
| `--deployment-style` | Deployment type (`IN_PLACE` or `BLUE_GREEN`) and option | `'{"deploymentType":"IN_PLACE","deploymentOption":"WITHOUT_TRAFFIC_CONTROL"}'` |

## How to Run the Demo

```bash
cd services/09-devtools/codedeploy
bash demo.sh
```

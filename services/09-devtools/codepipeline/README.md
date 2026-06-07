# AWS CodePipeline

## What is it?
AWS CodePipeline is a fully managed continuous delivery service that models, visualises, and automates the steps required to release software — from source code commit all the way through build, test, and deployment. You define a pipeline as an ordered sequence of stages, each containing one or more actions (source, build, test, deploy, approval), and CodePipeline automatically triggers and coordinates the execution of each action whenever a change is detected. It integrates natively with CodeCommit, CodeBuild, CodeDeploy, S3, CloudFormation, Elastic Beanstalk, Lambda, and many third-party tools such as GitHub and Jenkins. CodePipeline is the orchestration layer that ties the rest of the AWS Developer Tools suite together into a single, repeatable release process.

## Key Concepts
- **Pipeline** — the top-level workflow definition; an ordered list of stages that model the path code takes from source to production.
- **Stage** — a named logical phase in the pipeline (e.g. `Source`, `Build`, `Test`, `Deploy`) that must complete before the next stage begins.
- **Action** — a single task within a stage (e.g. pull source from CodeCommit, run a CodeBuild project, deploy with CodeDeploy). Actions within a stage can run in parallel if they have no dependencies.
- **Artifact** — a zipped bundle that is passed between actions as input or output; stored in the pipeline's designated S3 artifact bucket.
- **Transition** — the link between two consecutive stages; transitions can be disabled to pause the pipeline at a specific point.
- **Manual Approval Action** — a special action type that pauses the pipeline and waits for a human to approve or reject before proceeding.

## When to Use
- **End-to-end CI/CD automation** — automatically trigger a full build-test-deploy sequence every time a developer pushes code, eliminating manual steps between commit and production.
- **Multi-stage release workflows** — enforce an ordered promotion path (dev → staging → prod) with optional manual approval gates between environments.
- **Multi-service deployments** — coordinate parallel deployments to several services or regions from a single pipeline, ensuring they all succeed before marking the release done.
- **Infrastructure pipelines** — run `terraform apply` or `cdk deploy` inside a CodeBuild action to automate infrastructure changes with the same review and approval workflow as application code.

## CLI Quick Reference (awslocal)

### Create a pipeline
```bash
awslocal codepipeline create-pipeline --pipeline '{
  "name": "my-pipeline",
  "roleArn": "arn:aws:iam::000000000000:role/codepipeline-role",
  "artifactStore": {"type": "S3", "location": "my-artifact-bucket"},
  "stages": [
    {"name": "Source", "actions": [{
      "name": "SourceAction",
      "actionTypeId": {"category": "Source", "owner": "AWS", "provider": "S3", "version": "1"},
      "outputArtifacts": [{"name": "SourceOutput"}],
      "configuration": {"S3Bucket": "my-artifact-bucket", "S3ObjectKey": "source.zip"}
    }]},
    {"name": "Deploy", "actions": [{
      "name": "DeployAction",
      "actionTypeId": {"category": "Deploy", "owner": "AWS", "provider": "S3", "version": "1"},
      "inputArtifacts": [{"name": "SourceOutput"}],
      "configuration": {"BucketName": "my-artifact-bucket", "Extract": "true"}
    }]}
  ]
}'
```

### List pipelines
```bash
awslocal codepipeline list-pipelines \
  --query 'pipelines[].{Name:name,Version:version,Updated:updated}' \
  --output table
```

### Get pipeline definition
```bash
awslocal codepipeline get-pipeline --name my-pipeline
```

### Get pipeline state (execution status)
```bash
awslocal codepipeline get-pipeline-state \
  --name my-pipeline \
  --query 'stageStates[].{Stage:stageName,Status:latestExecution.status}' \
  --output table
```

### Start a manual execution
```bash
awslocal codepipeline start-pipeline-execution --name my-pipeline
```

### Disable / enable a stage transition
```bash
# Disable (pause the pipeline before the Deploy stage)
awslocal codepipeline disable-stage-transition \
  --pipeline-name my-pipeline \
  --stage-name Deploy \
  --transition-type Inbound \
  --reason "Awaiting change-control approval"

# Re-enable
awslocal codepipeline enable-stage-transition \
  --pipeline-name my-pipeline \
  --stage-name Deploy \
  --transition-type Inbound
```

### Tag a pipeline
```bash
awslocal codepipeline tag-resource \
  --resource-arn arn:aws:codepipeline:us-east-1:000000000000:my-pipeline \
  --tags key=Env,value=prod key=Team,value=platform
```

### Delete a pipeline
```bash
awslocal codepipeline delete-pipeline --name my-pipeline
```

## Example Walkthrough

1. **Create the IAM service role** — CodePipeline assumes this role to call CodeBuild, CodeDeploy, S3, and other services on your behalf.
   ```bash
   awslocal iam create-role \
     --role-name codepipeline-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codepipeline.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Create the S3 artifact bucket** — every artifact passed between stages is stored here; the bucket name must be unique.
   ```bash
   awslocal s3api create-bucket --bucket my-pipeline-artifacts
   ```

3. **Create the pipeline** — define two stages: `Source` (polls S3 for a new zip) and `Deploy` (extracts the zip back to S3).
   ```bash
   awslocal codepipeline create-pipeline --pipeline '{
     "name": "hello-pipeline",
     "roleArn": "arn:aws:iam::000000000000:role/codepipeline-role",
     "artifactStore": {"type": "S3", "location": "my-pipeline-artifacts"},
     "stages": [
       {"name": "Source", "actions": [{
         "name": "SourceAction",
         "actionTypeId": {"category": "Source", "owner": "AWS", "provider": "S3", "version": "1"},
         "outputArtifacts": [{"name": "SourceOutput"}],
         "configuration": {"S3Bucket": "my-pipeline-artifacts", "S3ObjectKey": "source.zip"}
       }]},
       {"name": "Deploy", "actions": [{
         "name": "DeployAction",
         "actionTypeId": {"category": "Deploy", "owner": "AWS", "provider": "S3", "version": "1"},
         "inputArtifacts": [{"name": "SourceOutput"}],
         "configuration": {"BucketName": "my-pipeline-artifacts", "Extract": "true"}
       }]}
     ]
   }' --query 'pipeline.{Name:name,Version:version}' --output table
   ```

4. **Inspect pipeline state** — check which stages have executed and what their current status is.
   ```bash
   awslocal codepipeline get-pipeline-state \
     --name hello-pipeline \
     --query 'stageStates[].{Stage:stageName,Status:latestExecution.status}' \
     --output table
   ```

5. **Manually trigger a pipeline execution** — simulate a new release without waiting for a source change to be detected.
   ```bash
   awslocal codepipeline start-pipeline-execution \
     --name hello-pipeline \
     --query 'pipelineExecutionId' \
     --output text
   ```

6. **Tag the pipeline** — apply metadata tags for cost allocation and environment identification.
   ```bash
   awslocal codepipeline tag-resource \
     --resource-arn "arn:aws:codepipeline:us-east-1:000000000000:hello-pipeline" \
     --tags key=Env,value=prod key=Team,value=platform
   ```

7. **Delete the pipeline** — tear down the pipeline definition when done (does not delete the S3 artifacts).
   ```bash
   awslocal codepipeline delete-pipeline --name hello-pipeline
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--pipeline` | Full pipeline definition as a JSON string or `file://` reference | `file://pipeline.json` |
| `--name` | Name of the pipeline to operate on | `hello-pipeline` |
| `--pipeline-name` | Pipeline name used with transition and execution commands | `hello-pipeline` |
| `--stage-name` | Name of the stage targeted by a transition or retry command | `Deploy` |
| `--transition-type` | Direction of a stage transition: `Inbound` or `Outbound` | `Inbound` |
| `--reason` | Human-readable explanation stored when disabling a transition | `"Pending approval"` |
| `--resource-arn` | Full ARN of the pipeline used for tagging and untagging | `arn:aws:codepipeline:us-east-1:000000000000:hello-pipeline` |
| `--tags` | Key-value pairs to attach to the pipeline | `key=Env,value=prod` |
| `--pipeline-execution-id` | ID of a specific execution used with `get-pipeline-execution` | `a1b2c3d4-...` |
| `--action-name` | Name of an individual action used with `put-approval-result` | `ManualApproval` |

## How to Run the Demo

```bash
cd services/09-devtools/codepipeline
bash demo.sh
```

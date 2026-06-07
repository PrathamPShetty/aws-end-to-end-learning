# AWS CodeBuild

## What is it?
AWS CodeBuild is a fully managed continuous integration service that compiles source code, runs tests, and produces deployable software artifacts — all without you having to provision or manage build servers. You define the build instructions in a `buildspec.yml` file (or inline), choose a managed build environment (a Docker image), and CodeBuild runs each build in a fresh, isolated container. Because you are billed only for the compute minutes your builds actually consume, CodeBuild is significantly cheaper than maintaining a permanently-running CI server for workloads with variable or infrequent build activity.

## Key Concepts
- **Project** — a named build configuration that ties together the source, environment, buildspec, and artifact destination.
- **Build** — a single execution of a project; each build gets its own isolated container, a unique build ID, and a full log stream.
- **Buildspec** — a YAML file (`buildspec.yml`) or inline string that defines the phases (`install`, `pre_build`, `build`, `post_build`) and the commands to run in each phase.
- **Environment** — the Docker image and compute type (CPU/memory tier) that CodeBuild uses to run the build container.
- **Artifact** — the output of a successful build (compiled binaries, zip files, Docker images) stored in S3 or pushed to ECR.
- **Cache** — an optional S3 or local layer cache that speeds up subsequent builds by reusing previously downloaded dependencies.

## When to Use
- **Continuous integration** — automatically compile and test every pull request or push to a branch so regressions are caught before merging.
- **Artifact packaging** — produce versioned deployment artifacts (Lambda zip files, Docker images, CloudFormation packages) as part of a CodePipeline stage.
- **Security scanning** — run static analysis tools (Bandit, Semgrep, OWASP Dependency-Check) inside a build phase without managing scanner infrastructure.
- **Infrastructure validation** — run `terraform plan` or `cdk synth` in a clean environment to validate infrastructure changes before applying them.

## CLI Quick Reference (awslocal)

### Create a build project
```bash
awslocal codebuild create-project \
  --name my-build \
  --source '{"type":"CODECOMMIT","location":"https://git-codecommit.us-east-1.amazonaws.com/v1/repos/hello-app"}' \
  --artifacts '{"type":"S3","location":"my-artifact-bucket"}' \
  --environment '{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:7.0","computeType":"BUILD_GENERAL1_SMALL"}' \
  --service-role arn:aws:iam::000000000000:role/codebuild-role
```

### List projects
```bash
awslocal codebuild list-projects \
  --query 'projects' \
  --output table
```

### Get / Describe a project
```bash
awslocal codebuild batch-get-projects \
  --names my-build \
  --query 'projects[].{Name:name,Status:created,Env:environment.image}' \
  --output table
```

### Start a build
```bash
awslocal codebuild start-build \
  --project-name my-build \
  --query 'build.{Id:id,Status:buildStatus}' \
  --output table
```

### Get build status
```bash
awslocal codebuild batch-get-builds \
  --ids my-build:abc123 \
  --query 'builds[].{Id:id,Status:buildStatus,Phase:currentPhase}' \
  --output table
```

### Update a project
```bash
awslocal codebuild update-project \
  --name my-build \
  --description "Updated CI project"
```

### Delete a project
```bash
awslocal codebuild delete-project --name my-build
```

## Example Walkthrough

1. **Create the IAM service role** — CodeBuild assumes this role to access S3, ECR, and other services during a build.
   ```bash
   awslocal iam create-role \
     --role-name codebuild-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codebuild.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Create an S3 bucket for artifacts** — build output will be uploaded here after a successful build.
   ```bash
   awslocal s3api create-bucket --bucket my-build-artifacts
   ```

3. **Create the build project** — define the source type, build environment, and artifact destination.
   ```bash
   awslocal codebuild create-project \
     --name hello-build \
     --source '{"type":"NO_SOURCE","buildspec":"version: 0.2\nphases:\n  build:\n    commands:\n      - echo Build complete at $(date)"}' \
     --artifacts '{"type":"S3","location":"my-build-artifacts"}' \
     --environment '{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:7.0","computeType":"BUILD_GENERAL1_SMALL"}' \
     --service-role "arn:aws:iam::000000000000:role/codebuild-role" \
     --query 'project.{Name:name,Created:created}' \
     --output table
   ```

4. **Start a build** — trigger a single execution of the project and capture the build ID.
   ```bash
   BUILD_ID=$(awslocal codebuild start-build \
     --project-name hello-build \
     --query 'build.id' --output text)
   echo "Build started: $BUILD_ID"
   ```

5. **Poll build status** — check the current phase and final status of the build.
   ```bash
   awslocal codebuild batch-get-builds \
     --ids "$BUILD_ID" \
     --query 'builds[].{Id:id,Status:buildStatus,Phase:currentPhase,StartTime:startTime}' \
     --output table
   ```

6. **List all builds for a project** — retrieve the IDs of every build that ran against this project.
   ```bash
   awslocal codebuild list-builds-for-project \
     --project-name hello-build \
     --query 'ids' \
     --output table
   ```

7. **Delete the project** — remove the project definition (does not delete build history or artifacts).
   ```bash
   awslocal codebuild delete-project --name hello-build
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--name` | Name of the build project | `hello-build` |
| `--source` | JSON object describing the source type and location | `'{"type":"CODECOMMIT","location":"..."}'` |
| `--artifacts` | JSON object describing where to store build output | `'{"type":"S3","location":"my-bucket"}'` |
| `--environment` | Docker image, compute tier, and environment variables for the build container | `'{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:7.0","computeType":"BUILD_GENERAL1_SMALL"}'` |
| `--service-role` | IAM role ARN that CodeBuild assumes during the build | `arn:aws:iam::000000000000:role/codebuild-role` |
| `--buildspec-override` | Override the project's buildspec for a single build run | `'version: 0.2\nphases:\n  build:\n    commands:\n      - make test'` |
| `--source-version` | Branch, tag, or commit ID to build (overrides project default) | `main`, `v1.2.0` |
| `--compute-type` | Compute tier: small, medium, large, 2xlarge | `BUILD_GENERAL1_MEDIUM` |
| `--image` | Docker image used as the build environment | `aws/codebuild/standard:7.0` |
| `--ids` | One or more build IDs for batch-get-builds (comma-separated) | `hello-build:abc123` |

## How to Run the Demo

```bash
cd services/09-devtools/codebuild
bash demo.sh
```

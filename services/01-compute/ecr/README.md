# Amazon ECR

## What is it?
Amazon Elastic Container Registry (ECR) is a fully managed Docker-compatible container image registry that lets you store, version, and deploy container images privately within AWS. Instead of relying on Docker Hub, you push images to an ECR repository and reference them directly in ECS Task Definitions, Lambda container functions, or EKS workloads — all within the same AWS account and region. ECR handles encryption at rest, integrates with IAM for access control, and supports automatic vulnerability scanning of images on push. It eliminates the need to run your own registry infrastructure.

## Key Concepts
- **Registry** — the account-level endpoint that hosts all repositories; its URL is `<account-id>.dkr.ecr.<region>.amazonaws.com`.
- **Repository** — a named collection of Docker image versions (similar to a single Docker Hub repository, e.g. `my-app`).
- **Image** — a versioned container artifact stored in a repository; identified by a tag (e.g. `latest`, `v1.2.3`) and/or a content-addressable digest (SHA256).
- **Image Tag** — a human-readable label (e.g. `v2.0.0`, `latest`) pointing to a specific image layer set.
- **Authorization Token** — a short-lived (12-hour) base64-encoded credential retrieved with `get-authorization-token` and used as the password for `docker login`.
- **Lifecycle Policy** — rules that automatically expire old or untagged images to control storage costs.
- **Image Scanning** — automated CVE vulnerability scanning triggered on push or on demand.

## When to Use
- **ECS / EKS deployments** — store your application images privately and pull them securely at deploy time without leaving the AWS network.
- **CI/CD pipelines** — push a freshly built image from GitHub Actions or CodeBuild to ECR, then trigger an ECS rolling deployment.
- **Multi-environment promotion** — use separate repositories or tags (`dev`, `staging`, `prod`) to promote the same image through environments.
- **Compliance and auditability** — use built-in image scanning and immutable tags to enforce that only approved, vulnerability-checked images reach production.

## CLI Quick Reference (awslocal)

### Create Repository
```bash
awslocal ecr create-repository \
  --repository-name my-app \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE
```

### List / Describe Repositories
```bash
awslocal ecr describe-repositories \
  --query 'repositories[].{Name:repositoryName,URI:repositoryUri,Scan:imageScanningConfiguration.scanOnPush}' \
  --output table
```

### Get Auth Token (for docker login)
```bash
# Retrieve and decode the token, then pipe to docker login
awslocal ecr get-authorization-token \
  --query 'authorizationData[0].authorizationToken' --output text | base64 -d | cut -d: -f2 | \
  docker login --username AWS --password-stdin \
    000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566
```

### Tag and Push an Image
```bash
REGISTRY="000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566"

docker tag my-app:latest "${REGISTRY}/my-app:latest"
docker push "${REGISTRY}/my-app:latest"
```

### List Images
```bash
awslocal ecr list-images --repository-name my-app
awslocal ecr describe-images \
  --repository-name my-app \
  --query 'imageDetails[].{Tag:imageTags[0],Digest:imageDigest,Size:imageSizeInBytes,Pushed:imagePushedAt}' \
  --output table
```

### Apply Lifecycle Policy
```bash
awslocal ecr put-lifecycle-policy \
  --repository-name my-app \
  --lifecycle-policy-text '{
    "rules":[{
      "rulePriority":1,
      "description":"Keep last 10 images",
      "selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":10},
      "action":{"type":"expire"}
    }]
  }'
```

### Delete Image
```bash
awslocal ecr batch-delete-image \
  --repository-name my-app \
  --image-ids imageTag=v1.0.0
```

### Delete Repository
```bash
awslocal ecr delete-repository --repository-name my-app --force
```

## Example Walkthrough

1. **Create an ECR repository** — provision a private registry for your app image.
   ```bash
   REPO_URI=$(awslocal ecr create-repository \
     --repository-name demo-repo \
     --image-scanning-configuration scanOnPush=true \
     --query 'repository.repositoryUri' --output text)
   echo "Repository URI: $REPO_URI"
   ```

2. **Retrieve an authorization token** — get a temporary password for Docker to authenticate with ECR.
   ```bash
   TOKEN=$(awslocal ecr get-authorization-token \
     --query 'authorizationData[0].authorizationToken' --output text)
   echo "Token length: ${#TOKEN}"
   ```

3. **Log Docker into ECR** — use the token to authenticate the Docker daemon against the registry.
   ```bash
   REGISTRY="000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566"
   docker login --username AWS --password "$TOKEN" "https://${REGISTRY}"
   ```

4. **Build and tag a Docker image** — create a minimal image and tag it with the ECR registry path.
   ```bash
   cat > Dockerfile <<'EOF'
   FROM alpine:3.18
   CMD ["echo", "Hello from ECR!"]
   EOF
   docker build -t demo-repo:latest .
   docker tag demo-repo:latest "${REGISTRY}/demo-repo:latest"
   ```

5. **Push the image to ECR** — upload the image layers to the repository.
   ```bash
   docker push "${REGISTRY}/demo-repo:latest"
   ```

6. **List images in the repository** — verify the image was stored successfully.
   ```bash
   awslocal ecr list-images \
     --repository-name demo-repo \
     --query 'imageIds[].{Tag:imageTag,Digest:imageDigest}' \
     --output table
   ```

7. **Apply a lifecycle policy** — automatically expire images once more than 5 exist.
   ```bash
   awslocal ecr put-lifecycle-policy \
     --repository-name demo-repo \
     --lifecycle-policy-text '{"rules":[{"rulePriority":1,"description":"Keep last 5","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":5},"action":{"type":"expire"}}]}'
   ```

8. **Delete the repository** — remove the repo and all its images.
   ```bash
   awslocal ecr delete-repository --repository-name demo-repo --force
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--repository-name` | Name of the ECR repository | `my-app` |
| `--image-scanning-configuration` | Enable/disable scan on push | `scanOnPush=true` |
| `--image-tag-mutability` | Allow or prevent tag overwrites | `IMMUTABLE` or `MUTABLE` |
| `--lifecycle-policy-text` | JSON lifecycle rules to auto-expire images | see examples above |
| `--image-ids` | Select images by tag or digest for operations | `imageTag=v1.0.0` or `imageDigest=sha256:...` |
| `--force` | Delete a non-empty repository without first removing images | (flag only) |
| `--registry-id` | Use a specific AWS account registry (defaults to caller's account) | `000000000000` |
| `--filter` | Filter `list-images` output by tag status | `tagStatus=TAGGED` |

## How to Run the Demo

```bash
cd services/01-compute/ecr
bash demo.sh
```

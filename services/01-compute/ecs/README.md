# Amazon ECS

## What is it?
Amazon Elastic Container Service (ECS) is a fully managed container orchestration service that lets you run Docker containers on AWS without managing the underlying cluster software (like Kubernetes). You describe your containerized workload in a Task Definition, group tasks into a Service for long-running applications, and ECS handles placement, scaling, health checks, and restarts. ECS integrates natively with IAM, CloudWatch, Elastic Load Balancing, and ECR, making it a natural fit for teams already using AWS. It supports two launch modes: Fargate (serverless — no EC2 instances to manage) and EC2 (you control the underlying hosts).

## Key Concepts
- **Cluster** — a logical grouping of tasks and services; the top-level ECS resource.
- **Task Definition** — a blueprint (JSON) describing one or more containers: image, CPU, memory, ports, environment variables, and IAM role.
- **Task** — a running instance of a Task Definition; the equivalent of a Kubernetes Pod.
- **Service** — keeps a desired number of tasks running, restarts failed tasks, and integrates with a load balancer for traffic distribution.
- **Container Definition** — the per-container section inside a Task Definition (image, command, port mappings, log configuration).
- **Launch Type** — `FARGATE` (AWS manages the compute) or `EC2` (you manage EC2 instances in the cluster).
- **Execution Role** — the IAM role ECS uses to pull images from ECR and write logs to CloudWatch on behalf of your task.

## When to Use
- **Microservices** — run each service as an ECS Service behind a load balancer, with independent scaling and deployment.
- **Web applications** — host a Dockerized web app (Node, Django, Rails, etc.) with automatic restarts, rolling deployments, and ALB integration.
- **Batch / one-off tasks** — run a container to completion (data migration, report export) using a standalone Task instead of a Service.
- **CI/CD pipelines** — spin up ephemeral containers to run tests or build artifacts without maintaining persistent build servers.

## CLI Quick Reference (awslocal)

### Create Cluster
```bash
awslocal ecs create-cluster --cluster-name my-cluster
```

### Register Task Definition
```bash
awslocal ecs register-task-definition \
  --family my-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu "256" --memory "512" \
  --execution-role-arn arn:aws:iam::000000000000:role/ecs-task-exec-role \
  --container-definitions '[{
    "name":"web",
    "image":"nginx:alpine",
    "portMappings":[{"containerPort":80,"protocol":"tcp"}],
    "essential":true
  }]'
```

### Create Service
```bash
awslocal ecs create-service \
  --cluster my-cluster \
  --service-name my-service \
  --task-definition my-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration 'awsvpcConfiguration={subnets=["subnet-xxxxxxxx"],securityGroups=["sg-xxxxxxxx"],assignPublicIp=DISABLED}'
```

### List / Describe
```bash
# List clusters
awslocal ecs list-clusters

# List services in a cluster
awslocal ecs list-services --cluster my-cluster

# Describe a service
awslocal ecs describe-services --cluster my-cluster --services my-service

# List running tasks
awslocal ecs list-tasks --cluster my-cluster

# Describe a task
awslocal ecs describe-tasks --cluster my-cluster --tasks <task-arn>
```

### Update Service (scale / redeploy)
```bash
awslocal ecs update-service \
  --cluster my-cluster \
  --service my-service \
  --desired-count 3

# Force a new deployment (redeploy with latest task definition)
awslocal ecs update-service \
  --cluster my-cluster \
  --service my-service \
  --force-new-deployment
```

### Delete
```bash
# Scale to 0 first, then delete the service
awslocal ecs update-service --cluster my-cluster --service my-service --desired-count 0
awslocal ecs delete-service --cluster my-cluster --service my-service

# Deregister a task definition revision
awslocal ecs deregister-task-definition --task-definition my-task:1

# Delete the cluster
awslocal ecs delete-cluster --cluster my-cluster
```

## Example Walkthrough

1. **Create an IAM task execution role** — ECS needs this to pull images and write logs.
   ```bash
   awslocal iam create-role \
     --role-name ecs-task-exec-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Create an ECS cluster** — a logical container for all your services and tasks.
   ```bash
   awslocal ecs create-cluster --cluster-name demo-cluster
   ```

3. **Register a Task Definition** — describe the nginx container with its CPU, memory, and port.
   ```bash
   awslocal ecs register-task-definition \
     --family demo-task \
     --network-mode awsvpc \
     --requires-compatibilities FARGATE \
     --cpu "256" --memory "512" \
     --execution-role-arn arn:aws:iam::000000000000:role/ecs-task-exec-role \
     --container-definitions '[{
       "name":"web",
       "image":"nginx:alpine",
       "portMappings":[{"containerPort":80,"protocol":"tcp"}],
       "essential":true,
       "logConfiguration":{"logDriver":"awslogs","options":{"awslogs-group":"/ecs/demo","awslogs-region":"us-east-1","awslogs-stream-prefix":"ecs"}}
     }]'
   ```

4. **Create a Service** — run 1 copy of the task and keep it running.
   ```bash
   awslocal ecs create-service \
     --cluster demo-cluster \
     --service-name demo-service \
     --task-definition demo-task \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration 'awsvpcConfiguration={subnets=["subnet-00000000"],securityGroups=["sg-00000000"],assignPublicIp=DISABLED}'
   ```

5. **List services and tasks** — confirm the service and task are running.
   ```bash
   awslocal ecs list-services --cluster demo-cluster
   awslocal ecs list-tasks   --cluster demo-cluster
   ```

6. **Scale the service** — increase the desired task count to 2.
   ```bash
   awslocal ecs update-service \
     --cluster demo-cluster \
     --service demo-service \
     --desired-count 2
   ```

7. **Delete the service and cluster** — tear everything down when done.
   ```bash
   awslocal ecs update-service --cluster demo-cluster --service demo-service --desired-count 0
   awslocal ecs delete-service --cluster demo-cluster --service demo-service
   awslocal ecs delete-cluster --cluster demo-cluster
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--cluster` | Cluster name or ARN | `demo-cluster` |
| `--family` | Task Definition family name | `demo-task` |
| `--requires-compatibilities` | Launch type compatibility | `FARGATE` or `EC2` |
| `--cpu` | vCPU units for the task (256 = 0.25 vCPU) | `"256"`, `"1024"` |
| `--memory` | Memory in MiB for the task | `"512"`, `"2048"` |
| `--execution-role-arn` | IAM role for pulling images and logging | `arn:aws:iam::000000000000:role/...` |
| `--container-definitions` | JSON array describing each container | see examples above |
| `--desired-count` | Number of tasks to keep running | `2` |
| `--launch-type` | Fargate (serverless) or EC2 | `FARGATE` |
| `--network-configuration` | VPC subnets, security groups, and public IP setting | `awsvpcConfiguration={...}` |
| `--force-new-deployment` | Trigger a rolling redeploy without changing the task definition | (flag only) |
| `--task-definition` | Family name or ARN:revision to use | `demo-task:3` |

## How to Run the Demo

```bash
cd services/01-compute/ecs
bash demo.sh
```

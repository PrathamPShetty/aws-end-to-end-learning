# AWS Batch

## What is it?
AWS Batch is a fully managed service for running large-scale batch computing workloads — jobs that run to completion rather than running continuously. You define a Job Definition (the container image and resource requirements), submit jobs to a Job Queue, and AWS Batch automatically provisions the right amount of compute (via a Compute Environment backed by Fargate or EC2) to run those jobs efficiently. It handles job scheduling, retries, and dependency chains, so you focus on the work rather than the infrastructure. AWS Batch is ideal for any workload that can be broken into discrete, parallelizable units: data processing, machine learning training, rendering, genomics, and more.

## Key Concepts
- **Job** — a single unit of work submitted for execution; it runs a container to completion and records exit status.
- **Job Definition** — a versioned template that describes the container image, command, resource requirements (vCPU, memory), IAM role, and retry strategy.
- **Job Queue** — a prioritized queue that holds submitted jobs waiting to be scheduled; linked to one or more Compute Environments.
- **Compute Environment** — the pool of compute resources (Fargate or EC2) that processes jobs from job queues; can be Managed (AWS scales it) or Unmanaged (you control it).
- **Job Dependencies** — a job can declare that it only starts after one or more other jobs succeed, enabling DAG-style pipelines.
- **Array Job** — a single job submission that fans out into N identical child jobs, each receiving a unique `AWS_BATCH_JOB_ARRAY_INDEX` environment variable.

## When to Use
- **ETL / data pipelines** — process millions of files from S3 by fanning out into hundreds of parallel Batch jobs, each handling a partition.
- **Machine learning training** — run hyperparameter-tuning experiments in parallel; each job trains a model with different parameters and writes results to S3.
- **Media transcoding** — encode video files at scale; submit one array job per file and Batch schedules workers automatically.
- **Scientific / genomics pipelines** — chain jobs with dependencies (quality-check → align → variant-call) where each stage waits for the previous to finish.

## CLI Quick Reference (awslocal)

### Create Compute Environment
```bash
awslocal batch create-compute-environment \
  --compute-environment-name my-compute-env \
  --type MANAGED \
  --state ENABLED \
  --compute-resources "type=FARGATE,maxvCpus=16,subnets=[subnet-xxxxxxxx],securityGroupIds=[sg-xxxxxxxx]" \
  --service-role arn:aws:iam::000000000000:role/batch-service-role
```

### Create Job Queue
```bash
awslocal batch create-job-queue \
  --job-queue-name my-job-queue \
  --state ENABLED \
  --priority 100 \
  --compute-environment-order "order=1,computeEnvironment=my-compute-env"
```

### Register Job Definition
```bash
awslocal batch register-job-definition \
  --job-definition-name my-job-def \
  --type container \
  --platform-capabilities FARGATE \
  --container-properties '{
    "image":"public.ecr.aws/amazonlinux/amazonlinux:2",
    "command":["echo","Hello from Batch"],
    "resourceRequirements":[
      {"type":"VCPU","value":"0.25"},
      {"type":"MEMORY","value":"512"}
    ],
    "executionRoleArn":"arn:aws:iam::000000000000:role/batch-instance-role",
    "networkConfiguration":{"assignPublicIp":"DISABLED"},
    "fargatePlatformConfiguration":{"platformVersion":"LATEST"}
  }'
```

### Submit Job
```bash
JOB_ID=$(awslocal batch submit-job \
  --job-name my-run-001 \
  --job-queue my-job-queue \
  --job-definition my-job-def \
  --query 'jobId' --output text)
echo "Job ID: $JOB_ID"
```

### List / Describe Jobs
```bash
# List jobs by status
awslocal batch list-jobs \
  --job-queue my-job-queue \
  --job-status RUNNING

# Describe specific job
awslocal batch describe-jobs \
  --jobs "$JOB_ID" \
  --query 'jobs[].{Name:jobName,Status:status,Queue:jobQueue,Reason:statusReason}' \
  --output table
```

### List / Describe Infrastructure
```bash
# List compute environments
awslocal batch describe-compute-environments \
  --query 'computeEnvironments[].{Name:computeEnvironmentName,State:state,Status:status}' \
  --output table

# List job queues
awslocal batch describe-job-queues \
  --query 'jobQueues[].{Name:jobQueueName,State:state,Priority:priority}' \
  --output table

# List job definitions
awslocal batch describe-job-definitions \
  --query 'jobDefinitions[].{Name:jobDefinitionName,Revision:revision,Status:status}' \
  --output table
```

### Update
```bash
# Disable a job queue (required before deletion)
awslocal batch update-job-queue \
  --job-queue my-job-queue \
  --state DISABLED

# Disable a compute environment (required before deletion)
awslocal batch update-compute-environment \
  --compute-environment my-compute-env \
  --state DISABLED
```

### Delete
```bash
# Must disable and delete queue before the compute environment
awslocal batch update-job-queue --job-queue my-job-queue --state DISABLED
awslocal batch delete-job-queue --job-queue my-job-queue

awslocal batch update-compute-environment --compute-environment my-compute-env --state DISABLED
awslocal batch delete-compute-environment --compute-environment my-compute-env

# Deregister a job definition
awslocal batch deregister-job-definition --job-definition my-job-def:1
```

## Example Walkthrough

1. **Create IAM roles** — Batch needs a service role and the container needs an execution role.
   ```bash
   awslocal iam create-role \
     --role-name batch-service-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"batch.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

   awslocal iam create-role \
     --role-name batch-instance-role \
     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
   ```

2. **Create a Compute Environment** — define a Fargate-backed pool with a maximum of 4 vCPUs.
   ```bash
   awslocal batch create-compute-environment \
     --compute-environment-name demo-compute-env \
     --type MANAGED \
     --state ENABLED \
     --compute-resources "type=FARGATE,maxvCpus=4,subnets=[subnet-00000000],securityGroupIds=[sg-00000000]" \
     --service-role arn:aws:iam::000000000000:role/batch-service-role
   ```

3. **Create a Job Queue** — link the queue to the compute environment with priority 100.
   ```bash
   awslocal batch create-job-queue \
     --job-queue-name demo-job-queue \
     --state ENABLED \
     --priority 100 \
     --compute-environment-order "order=1,computeEnvironment=demo-compute-env"
   ```

4. **Register a Job Definition** — describe the container that will run for each job.
   ```bash
   awslocal batch register-job-definition \
     --job-definition-name demo-job-def \
     --type container \
     --platform-capabilities FARGATE \
     --container-properties '{
       "image":"public.ecr.aws/amazonlinux/amazonlinux:2",
       "command":["echo","Hello from AWS Batch"],
       "resourceRequirements":[
         {"type":"VCPU","value":"0.25"},
         {"type":"MEMORY","value":"512"}
       ],
       "executionRoleArn":"arn:aws:iam::000000000000:role/batch-instance-role",
       "networkConfiguration":{"assignPublicIp":"DISABLED"},
       "fargatePlatformConfiguration":{"platformVersion":"LATEST"}
     }'
   ```

5. **Submit a job** — enqueue a single run using the job definition and queue.
   ```bash
   JOB_ID=$(awslocal batch submit-job \
     --job-name demo-run-001 \
     --job-queue demo-job-queue \
     --job-definition demo-job-def \
     --query 'jobId' --output text)
   echo "Submitted job: $JOB_ID"
   ```

6. **Check job status** — inspect the job's status and any failure reason.
   ```bash
   awslocal batch describe-jobs \
     --jobs "$JOB_ID" \
     --query 'jobs[].{Name:jobName,Status:status,Queue:jobQueue}' \
     --output table
   ```

7. **List all job queues** — confirm the queue is ENABLED and linked to the compute environment.
   ```bash
   awslocal batch describe-job-queues \
     --query 'jobQueues[].{Name:jobQueueName,State:state,Priority:priority}' \
     --output table
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--compute-environment-name` | Unique name for the compute environment | `demo-compute-env` |
| `--type` (compute env) | `MANAGED` (AWS scales) or `UNMANAGED` | `MANAGED` |
| `--compute-resources` | Compute type, max vCPUs, subnets, security groups | `type=FARGATE,maxvCpus=16,...` |
| `--job-queue-name` | Name of the job queue | `demo-job-queue` |
| `--priority` | Integer; higher number = higher priority when multiple queues share a compute env | `100` |
| `--compute-environment-order` | Ordered list of compute environments for the queue | `order=1,computeEnvironment=...` |
| `--job-definition-name` | Name for the job definition family | `demo-job-def` |
| `--platform-capabilities` | Target compute platform | `FARGATE` or `EC2` |
| `--container-properties` | JSON blob describing image, command, CPU, memory, roles | see examples above |
| `--job-name` | Human-readable label for the submitted job run | `my-run-001` |
| `--job-queue` | Queue to submit the job to | `demo-job-queue` |
| `--job-definition` | Definition name (and optionally `:revision`) to use | `demo-job-def:3` |
| `--depends-on` | List of job IDs this job must wait for | `jobId=abc-123,type=N_TO_N` |
| `--array-properties` | Fan out into N child jobs | `size=100` |

## How to Run the Demo

```bash
cd services/01-compute/batch
bash demo.sh
```

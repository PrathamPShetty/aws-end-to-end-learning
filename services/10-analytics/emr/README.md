# Amazon EMR

## What is it?
Amazon EMR (Elastic MapReduce) is a managed cluster platform that runs big-data frameworks such as Apache Spark, Hadoop, Hive, Presto, and HBase on dynamically provisioned EC2 instances. It handles cluster provisioning, configuration, and tuning so you can focus on your analytics workloads rather than infrastructure. EMR is the right choice when you need to process terabytes or petabytes of data with full control over the execution environment, custom Spark configurations, or open-source frameworks not available in serverless services. Clusters can run continuously (long-running) or terminate automatically after a batch job finishes (transient), keeping costs tightly controlled.

## Key Concepts
- **Cluster** — A named group of EC2 instances (nodes) provisioned to run big-data workloads; identified by a Cluster ID (e.g. `j-XXXXXXXXXXXXX`).
- **Instance Group** — A role-based set of nodes within a cluster: one **Master** (coordinates jobs), one or more **Core** nodes (store HDFS data and run tasks), and optional **Task** nodes (run tasks only, no HDFS).
- **Step** — A unit of work submitted to a cluster (e.g. a Spark application, a Hive script); steps are queued and executed in order.
- **Release Label** — The versioned EMR software bundle (e.g. `emr-6.9.0`) that determines the versions of Spark, Hadoop, Hive, etc. installed on the cluster.
- **Bootstrap Action** — A shell script that runs on every node during cluster startup, before applications are installed; used for custom software or configuration.
- **Auto-termination** — A setting that shuts down a cluster automatically after all steps complete, preventing idle charges.

## When to Use
- **Large-scale Spark ETL** — Transform and aggregate terabytes of raw S3 data into clean Parquet datasets when the dataset is too large for serverless options.
- **Machine learning training** — Run distributed training jobs using Spark MLlib or custom Python on a cluster sized to your dataset.
- **Ad-hoc Hive or Presto queries** — Spin up a transient cluster for complex SQL analytics that require custom configurations or UDFs not supported by Athena.
- **Streaming pipelines** — Use Spark Structured Streaming on a long-running cluster to process Kinesis or Kafka streams in near-real-time.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create cluster | `awslocal emr create-cluster --name my-cluster --release-label emr-6.9.0 --applications Name=Spark Name=Hadoop --instance-type m5.xlarge --instance-count 3 --use-default-roles --no-auto-terminate` |
| List clusters | `awslocal emr list-clusters --query 'Clusters[].{Id:Id,Name:Name,State:Status.State}'` |
| Describe cluster | `awslocal emr describe-cluster --cluster-id j-XXXXXXXXXXXXX` |
| Add a step | `awslocal emr add-steps --cluster-id j-XXXXXXXXXXXXX --steps '[{"Name":"MyStep","ActionOnFailure":"CONTINUE","HadoopJarStep":{"Jar":"command-runner.jar","Args":["spark-submit","s3://my-bucket/app.jar"]}}]'` |
| List steps | `awslocal emr list-steps --cluster-id j-XXXXXXXXXXXXX` |
| Describe step | `awslocal emr describe-step --cluster-id j-XXXXXXXXXXXXX --step-id s-XXXXXXXXXXXXX` |
| Cancel step | `awslocal emr cancel-steps --cluster-id j-XXXXXXXXXXXXX --step-ids s-XXXXXXXXXXXXX` |
| Terminate cluster | `awslocal emr terminate-clusters --cluster-ids j-XXXXXXXXXXXXX` |

## Example Walkthrough

1. **Create an S3 bucket** for EMR logs and job artifacts:
   ```bash
   awslocal s3 mb s3://emr-demo-bucket
   ```

2. **Create an EMR cluster** with Spark and Hadoop, logging to S3:
   ```bash
   CLUSTER_ID=$(awslocal emr create-cluster \
     --name "emr-demo-cluster" \
     --release-label "emr-6.9.0" \
     --applications Name=Spark Name=Hadoop \
     --instance-type "m5.xlarge" \
     --instance-count 2 \
     --log-uri "s3://emr-demo-bucket/logs/" \
     --use-default-roles \
     --no-auto-terminate \
     --query 'ClusterId' --output text)
   echo "Cluster ID: $CLUSTER_ID"
   ```

3. **Describe the cluster** to inspect its state, release label, and log URI:
   ```bash
   awslocal emr describe-cluster \
     --cluster-id "$CLUSTER_ID" \
     --query 'Cluster.{Id:Id,Name:Name,State:Status.State,Release:ReleaseLabel,LogUri:LogUri}' \
     --output table
   ```

4. **List all clusters** in the account to confirm the new cluster appears:
   ```bash
   awslocal emr list-clusters \
     --query 'Clusters[].{Id:Id,Name:Name,State:Status.State}' \
     --output table
   ```

5. **Add a Spark step** that runs the bundled SparkPi example:
   ```bash
   STEP_ID=$(awslocal emr add-steps \
     --cluster-id "$CLUSTER_ID" \
     --steps '[{
       "Name": "SparkPi",
       "ActionOnFailure": "CONTINUE",
       "HadoopJarStep": {
         "Jar": "command-runner.jar",
         "Args": [
           "spark-submit",
           "--class", "org.apache.spark.examples.SparkPi",
           "/usr/lib/spark/examples/jars/spark-examples.jar",
           "10"
         ]
       }
     }]' \
     --query 'StepIds[0]' --output text)
   echo "Step ID: $STEP_ID"
   ```

6. **List steps** on the cluster to check the step status:
   ```bash
   awslocal emr list-steps \
     --cluster-id "$CLUSTER_ID" \
     --query 'Steps[].{Id:Id,Name:Name,State:Status.State}' \
     --output table
   ```

7. **Terminate the cluster** to stop incurring charges after the work is done:
   ```bash
   awslocal emr terminate-clusters --cluster-ids "$CLUSTER_ID"
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--release-label` | Versioned EMR bundle (e.g. `emr-6.9.0`) that determines installed framework versions. |
| `--applications` | Space-separated list of apps to install: `Name=Spark`, `Name=Hadoop`, `Name=Hive`, `Name=Presto`, etc. |
| `--instance-type` | EC2 instance type for all nodes (e.g. `m5.xlarge`). Affects memory, CPU, and cost. |
| `--instance-count` | Total number of instances; first is the master, remaining are core nodes. |
| `--use-default-roles` | Automatically uses `EMR_DefaultRole` (service) and `EMR_EC2_DefaultRole` (instance profile). |
| `--no-auto-terminate` | Keeps the cluster running after all steps complete (long-running mode). Omit for transient clusters. |
| `--log-uri` | S3 URI where EMR writes cluster and step logs (e.g. `s3://my-bucket/logs/`). |
| `--ec2-attributes` | Specifies `KeyName`, `SubnetId`, `EmrManagedMasterSecurityGroup`, etc. for network/SSH access. |
| `--steps` | JSON array of step definitions to queue immediately at cluster creation. |
| `--ActionOnFailure` | Per-step behaviour if the step fails: `TERMINATE_CLUSTER`, `CANCEL_AND_WAIT`, or `CONTINUE`. |
| `--bootstrap-actions` | List of shell scripts (S3 paths) to run on each node before application installation. |

## How to Run the Demo
```bash
cd services/10-analytics/emr
bash demo.sh
```

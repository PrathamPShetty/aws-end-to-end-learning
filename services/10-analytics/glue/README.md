# AWS Glue

## What is it?
AWS Glue is a fully managed, serverless extract-transform-load (ETL) service that makes it easy to discover, prepare, and combine data for analytics, machine learning, and application development. It provides a central metadata repository called the Glue Data Catalog — a drop-in Hive-compatible metastore used by Athena, EMR, and Redshift Spectrum. Glue auto-generates ETL code in Python or Scala (using Apache Spark under the hood) and can crawl data sources to infer schemas automatically. Use it when you need to move and transform data between stores without managing servers or writing low-level Spark boilerplate.

## Key Concepts
- **Data Catalog** — A managed Hive-compatible metadata repository that stores database and table definitions; shared across Athena, EMR, and Redshift Spectrum.
- **Database** — A namespace inside the Data Catalog that groups related tables (not a storage engine; metadata only).
- **Table** — A catalog entry describing the schema, location, format, and SerDe of a dataset stored in S3 or another source.
- **Crawler** — An automated job that connects to a data store, samples files, infers schema, and writes table definitions into the Data Catalog.
- **ETL Job** — A serverless Spark or Python Shell script that reads from a source, applies transformations, and writes to a target; defined by a script location in S3 and an IAM role.
- **Job Run** — A single execution of a Glue ETL job; has its own run ID, status, start time, and CloudWatch log stream.

## When to Use
- **Building a data lake catalog** — Crawl S3 buckets containing CSV, JSON, or Parquet files to register schemas in the Data Catalog so Athena can query them immediately.
- **Nightly ETL pipelines** — Transform raw application data from RDS or S3 into clean, partitioned Parquet tables in a data lake on a scheduled trigger.
- **Schema evolution management** — Let Glue crawlers detect new columns or partitions added by upstream systems and update the catalog automatically.
- **Cross-service data sharing** — Publish a single catalog entry consumed by Athena for ad-hoc queries, EMR for heavy batch processing, and Redshift Spectrum for BI workloads.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create database | `awslocal glue create-database --database-input Name=sales_catalog,Description="Sales data catalog"` |
| List databases | `awslocal glue get-databases --query 'DatabaseList[].Name'` |
| Get database | `awslocal glue get-database --name sales_catalog` |
| Create table | `awslocal glue create-table --database-name sales_catalog --table-input '{"Name":"orders","StorageDescriptor":{...}}'` |
| List tables | `awslocal glue get-tables --database-name sales_catalog --query 'TableList[].Name'` |
| Get table | `awslocal glue get-table --database-name sales_catalog --name orders` |
| Update table | `awslocal glue update-table --database-name sales_catalog --table-input '{"Name":"orders",...}'` |
| Delete table | `awslocal glue delete-table --database-name sales_catalog --name orders` |
| Create ETL job | `awslocal glue create-job --name my-etl-job --role arn:aws:iam::000000000000:role/glue-role --command Name=glueetl,ScriptLocation=s3://my-bucket/scripts/etl.py,PythonVersion=3` |
| List jobs | `awslocal glue list-jobs --query 'JobNames'` |
| Start job run | `awslocal glue start-job-run --job-name my-etl-job` |
| Get job run | `awslocal glue get-job-run --job-name my-etl-job --run-id <RUN_ID>` |
| Delete job | `awslocal glue delete-job --job-name my-etl-job` |
| Delete database | `awslocal glue delete-database --name sales_catalog` |

## Example Walkthrough

1. **Create an S3 bucket and upload a sample CSV** for Glue to catalog:
   ```bash
   awslocal s3 mb s3://glue-demo-bucket
   printf 'id,name,score\n1,Alice,95\n2,Bob,87\n3,Carol,92\n' \
     | awslocal s3 cp - s3://glue-demo-bucket/input/scores.csv
   ```

2. **Create a Glue catalog database** to hold your table definitions:
   ```bash
   awslocal glue create-database \
     --database-input Name=glue_catalog_db,Description="Demo catalog database"
   ```

3. **Register an external table** pointing to the CSV data in S3:
   ```bash
   awslocal glue create-table \
     --database-name glue_catalog_db \
     --table-input '{
       "Name": "scores",
       "TableType": "EXTERNAL_TABLE",
       "StorageDescriptor": {
         "Columns": [
           {"Name": "id",    "Type": "int"},
           {"Name": "name",  "Type": "string"},
           {"Name": "score", "Type": "int"}
         ],
         "Location": "s3://glue-demo-bucket/input/",
         "InputFormat":  "org.apache.hadoop.mapred.TextInputFormat",
         "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
         "SerdeInfo": {
           "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
           "Parameters": {"field.delim": ","}
         }
       }
     }'
   ```

4. **Confirm the table was registered** by listing tables in the database:
   ```bash
   awslocal glue get-tables \
     --database-name glue_catalog_db \
     --query 'TableList[].{Name:Name,Type:TableType,Location:StorageDescriptor.Location}' \
     --output table
   ```

5. **Create a Glue ETL job** referencing a PySpark script stored in S3:
   ```bash
   awslocal glue create-job \
     --name glue-etl-job \
     --role arn:aws:iam::000000000000:role/glue-demo-role \
     --command Name=glueetl,ScriptLocation=s3://glue-demo-bucket/scripts/etl.py,PythonVersion=3 \
     --glue-version "3.0"
   ```

6. **List all ETL jobs** to confirm the job was created:
   ```bash
   awslocal glue list-jobs \
     --query 'JobNames' \
     --output table
   ```

7. **Start a job run** and capture the run ID for status polling:
   ```bash
   RUN_ID=$(awslocal glue start-job-run \
     --job-name glue-etl-job \
     --query 'JobRunId' --output text)
   echo "Job run ID: $RUN_ID"
   ```

8. **Check the job run status** to see if it completed successfully:
   ```bash
   awslocal glue get-job-run \
     --job-name glue-etl-job \
     --run-id "$RUN_ID" \
     --query 'JobRun.{State:JobRunState,Start:StartedOn,Error:ErrorMessage}' \
     --output table
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--database-input` | JSON or shorthand object with `Name`, `Description`, and optional `LocationUri` for a catalog database. |
| `--table-input` | JSON object defining the table: `Name`, `TableType`, `StorageDescriptor` (columns, location, SerDe), and optional `PartitionKeys`. |
| `--database-name` | Name of the Glue catalog database the operation targets. |
| `--role` | IAM role ARN that the ETL job assumes to access S3, CloudWatch Logs, and other services. |
| `--command` | Defines job type and script: `Name` (`glueetl` for Spark, `pythonshell` for Python), `ScriptLocation` (S3 URI), `PythonVersion`. |
| `--glue-version` | Spark/Python runtime version for the job (e.g. `3.0`, `4.0`). Determines available Spark and Python versions. |
| `--number-of-workers` | Number of Glue DPU workers to allocate to a job run; more workers = faster but higher cost. |
| `--worker-type` | Worker size: `Standard`, `G.1X`, `G.2X`, `G.025X` (Python shell). Controls memory and vCPUs per worker. |
| `--arguments` | Key-value pairs passed as job parameters; accessible inside the script via `getResolvedOptions`. |
| `--max-retries` | Number of times Glue automatically retries a failed job run (0–10). |

## How to Run the Demo
```bash
cd services/10-analytics/glue
bash demo.sh
```

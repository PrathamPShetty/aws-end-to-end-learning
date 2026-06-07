# Amazon Athena

## What is it?
Amazon Athena is a serverless, interactive query service that lets you analyze data stored in Amazon S3 using standard SQL — no infrastructure to set up or manage. It uses Presto under the hood and integrates with the AWS Glue Data Catalog to discover table schemas automatically. Athena is ideal when you want ad-hoc SQL analytics over files (CSV, JSON, Parquet, ORC) that already live in S3 without moving or transforming them first. You pay only per query, based on the amount of data scanned, making it extremely cost-effective for exploratory analysis.

## Key Concepts
- **Workgroup** — A named container that groups queries together, enforces per-query data-scan limits, and routes results to a specific S3 output location.
- **Database** — A logical namespace inside the Glue Data Catalog that groups related tables; created with a `CREATE DATABASE` DDL query.
- **External Table** — A table whose schema is stored in the catalog but whose data lives in S3; Athena never copies or owns the underlying files.
- **Query Execution ID** — A unique identifier returned when you submit a query; used to poll status and retrieve results.
- **Result Location** — The S3 prefix where Athena writes query result CSV files and metadata after each execution.
- **Partition** — A folder-level subdivision of an S3 dataset (e.g. `year=2024/month=01/`) that Athena can prune to reduce data scanned and lower cost.

## When to Use
- **Ad-hoc log analysis** — Query CloudTrail, ALB access logs, or VPC Flow Logs stored in S3 with SQL without loading them into a database.
- **Business intelligence reporting** — Connect BI tools (Tableau, QuickSight) via the Athena JDBC/ODBC driver to query Parquet data lakes in S3.
- **Cost-efficient data exploration** — Explore large datasets stored cheaply in S3 before deciding whether to load them into Redshift or RDS.
- **Cross-account data sharing** — Query data owned by another AWS account's S3 bucket without copying it, using Lake Formation permissions.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Start a query | `awslocal athena start-query-execution --query-string "SELECT 1" --result-configuration OutputLocation=s3://my-bucket/results/` |
| Get query status | `awslocal athena get-query-execution --query-execution-id <QID>` |
| Get query results | `awslocal athena get-query-results --query-execution-id <QID>` |
| List executions | `awslocal athena list-query-executions` |
| Stop a running query | `awslocal athena stop-query-execution --query-execution-id <QID>` |
| List workgroups | `awslocal athena list-work-groups` |
| Create workgroup | `awslocal athena create-work-group --name analytics-team --configuration ResultConfiguration={OutputLocation=s3://my-bucket/results/}` |
| Delete workgroup | `awslocal athena delete-work-group --work-group analytics-team --recursive-delete-option` |

## Example Walkthrough

1. **Create an S3 bucket and upload a sample CSV** that Athena will query:
   ```bash
   awslocal s3 mb s3://athena-demo-bucket
   printf 'order_id,product,amount\n1,Widget,19.99\n2,Gadget,49.99\n3,Widget,19.99\n4,Doohickey,9.99\n' \
     | awslocal s3 cp - s3://athena-demo-bucket/data/orders/orders.csv
   ```

2. **Create a database** by running a DDL query through Athena:
   ```bash
   awslocal athena start-query-execution \
     --query-string "CREATE DATABASE IF NOT EXISTS sales_db" \
     --result-configuration OutputLocation=s3://athena-demo-bucket/query-results/
   ```

3. **Create an external table** that maps to the CSV file on S3:
   ```bash
   awslocal athena start-query-execution \
     --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS sales_db.orders (
         order_id INT, product STRING, amount DOUBLE
       )
       ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
       LOCATION 's3://athena-demo-bucket/data/orders/'
       TBLPROPERTIES ('skip.header.line.count'='1')" \
     --result-configuration OutputLocation=s3://athena-demo-bucket/query-results/
   ```

4. **Run an aggregation query** to sum sales totals grouped by product:
   ```bash
   QID=$(awslocal athena start-query-execution \
     --query-string "SELECT product, COUNT(*) AS orders, SUM(amount) AS total
                     FROM sales_db.orders
                     GROUP BY product ORDER BY total DESC" \
     --result-configuration OutputLocation=s3://athena-demo-bucket/query-results/ \
     --query 'QueryExecutionId' --output text)
   echo "Query ID: $QID"
   ```

5. **Check the query status** to confirm it succeeded:
   ```bash
   awslocal athena get-query-execution \
     --query-execution-id "$QID" \
     --query 'QueryExecution.Status.{State:State,Reason:StateChangeReason}' \
     --output table
   ```

6. **Retrieve the query results** and inspect the rows returned:
   ```bash
   awslocal athena get-query-results \
     --query-execution-id "$QID" \
     --query 'ResultSet.Rows[*].Data[*].VarCharValue' \
     --output table
   ```

7. **List all recent query execution IDs** for auditing or reuse:
   ```bash
   awslocal athena list-query-executions \
     --query 'QueryExecutionIds' \
     --output table
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--query-string` | The SQL statement to execute. Wrap in quotes; use `\` for multi-line strings. |
| `--result-configuration` | Required. Specifies `OutputLocation` (S3 URI) where result CSVs are written. |
| `--query-execution-id` | The UUID of a previously submitted query; used with `get-query-execution` and `get-query-results`. |
| `--work-group` | Routes the query to a named workgroup (default is `primary`). |
| `--execution-parameters` | Parameterized query values (list of strings matching `?` placeholders). |
| `--result-reuse-configuration` | Enables result reuse within a TTL window to avoid re-scanning identical queries. |
| `--database` | Shorthand to set the default database context without a `USE` statement. |
| `--recursive-delete-option` | Used with `delete-work-group`; also deletes all named queries in the group. |

## How to Run the Demo
```bash
cd services/10-analytics/athena
bash demo.sh
```

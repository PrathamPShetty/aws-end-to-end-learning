# Amazon Timestream

## What is it?
Amazon Timestream is a fast, scalable, serverless time-series database designed specifically for storing and analysing data that changes over time — such as application metrics, sensor readings, and IoT telemetry. It automatically tiers data between an in-memory store for recent data and a cost-optimised magnetic store for historical data, so you get fast query performance without managing storage yourself. Timestream includes built-in time-series analytics functions (interpolation, smoothing, approximate aggregates) that would otherwise require custom application logic or expensive migrations to specialised tools. Because it is serverless, there are no clusters to size or provision — it scales automatically to handle millions of writes per second.

## Key Concepts
- **Database** — A top-level namespace within Timestream that groups one or more tables; analogous to a database in a relational system.
- **Table** — A container for time-series records; each table has its own retention policy controlling how long data stays in the memory store and magnetic store.
- **Record** — A single data point consisting of: dimensions (metadata labels), a measure name, a measure value, a measure value type, and a timestamp.
- **Dimension** — A key-value label that describes the source of a measurement (e.g., `host=web-01`, `region=us-east-1`); used to filter and group query results.
- **Measure** — The actual observed value (e.g., `cpu_utilization = 72.5`); a record has one measure but a multi-measure record can hold several.
- **Retention Policy** — Per-table settings for `MemoryStoreRetentionPeriodInHours` (hot tier, fast queries) and `MagneticStoreRetentionPeriodInDays` (cold tier, cost-efficient).

## When to Use
- **Infrastructure and application monitoring** — Collect CPU, memory, disk, and network metrics from thousands of servers every second and query trends or anomalies in real time.
- **IoT sensor data** — Ingest temperature, pressure, vibration, and GPS readings from fleets of connected devices and run analytics without pre-provisioning capacity.
- **DevOps observability pipelines** — Store custom application metrics emitted by microservices and query them alongside CloudWatch data for unified performance visibility.
- **Financial tick data** — Record trade prices, bid/ask spreads, and volumes at millisecond resolution and query rolling averages or peak windows efficiently.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create database | `awslocal timestream-write create-database --database-name demo_metrics` |
| List databases | `awslocal timestream-write list-databases` |
| Create table | `awslocal timestream-write create-table --database-name demo_metrics --table-name cpu_usage --retention-properties "MemoryStoreRetentionPeriodInHours=24,MagneticStoreRetentionPeriodInDays=7"` |
| List tables | `awslocal timestream-write list-tables --database-name demo_metrics` |
| Describe table | `awslocal timestream-write describe-table --database-name demo_metrics --table-name cpu_usage` |
| Write records | `awslocal timestream-write write-records --database-name demo_metrics --table-name cpu_usage --records '[...]'` |
| Run query | `awslocal timestream-query query --query-string "SELECT * FROM demo_metrics.cpu_usage LIMIT 10"` |
| Delete table | `awslocal timestream-write delete-table --database-name demo_metrics --table-name cpu_usage` |
| Delete database | `awslocal timestream-write delete-database --database-name demo_metrics` |

## Example Walkthrough

1. **Create a Timestream database** as the namespace for your metrics:
   ```bash
   awslocal timestream-write create-database \
     --database-name demo_metrics
   ```

2. **Create a table** with a 24-hour memory store and 7-day magnetic store retention:
   ```bash
   awslocal timestream-write create-table \
     --database-name demo_metrics \
     --table-name cpu_usage \
     --retention-properties "MemoryStoreRetentionPeriodInHours=24,MagneticStoreRetentionPeriodInDays=7"
   ```

3. **Write time-series records** for two hosts at the current timestamp:
   ```bash
   NOW=$(date +%s%3N)
   awslocal timestream-write write-records \
     --database-name demo_metrics \
     --table-name cpu_usage \
     --records "[
       {\"Dimensions\":[{\"Name\":\"host\",\"Value\":\"web-01\"},{\"Name\":\"region\",\"Value\":\"us-east-1\"}],
        \"MeasureName\":\"cpu_utilization\",\"MeasureValue\":\"72.5\",\"MeasureValueType\":\"DOUBLE\",
        \"Time\":\"${NOW}\",\"TimeUnit\":\"MILLISECONDS\"},
       {\"Dimensions\":[{\"Name\":\"host\",\"Value\":\"web-02\"},{\"Name\":\"region\",\"Value\":\"us-east-1\"}],
        \"MeasureName\":\"cpu_utilization\",\"MeasureValue\":\"45.1\",\"MeasureValueType\":\"DOUBLE\",
        \"Time\":\"${NOW}\",\"TimeUnit\":\"MILLISECONDS\"}
     ]"
   ```

4. **Describe the table** to confirm retention settings and current status:
   ```bash
   awslocal timestream-write describe-table \
     --database-name demo_metrics \
     --table-name cpu_usage \
     --query 'Table.{Name:TableName,DB:DatabaseName,Status:TableStatus}' \
     --output table
   ```

5. **Query the table** using standard SQL with Timestream time-series extensions:
   ```bash
   awslocal timestream-query query \
     --query-string "SELECT host, measure_value::double AS cpu_pct, time
                     FROM demo_metrics.cpu_usage
                     ORDER BY time DESC
                     LIMIT 10"
   ```

6. **List all tables** in the database:
   ```bash
   awslocal timestream-write list-tables \
     --database-name demo_metrics \
     --query 'Tables[*].{Name:TableName,Status:TableStatus}' \
     --output table
   ```

7. **Clean up** by deleting the table and then the database:
   ```bash
   awslocal timestream-write delete-table \
     --database-name demo_metrics \
     --table-name cpu_usage
   awslocal timestream-write delete-database \
     --database-name demo_metrics
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--database-name` | Name of the Timestream database to target. |
| `--table-name` | Name of the table within the specified database. |
| `--retention-properties` | Sets `MemoryStoreRetentionPeriodInHours` (1–8766) and `MagneticStoreRetentionPeriodInDays` (1–73000). |
| `--records` | JSON array of record objects to write; each record requires `Dimensions`, `MeasureName`, `MeasureValue`, `MeasureValueType`, `Time`, and `TimeUnit`. |
| `--time-unit` | Granularity of the `Time` field in a record: `SECONDS`, `MILLISECONDS`, `MICROSECONDS`, or `NANOSECONDS`. |
| `--measure-value-type` | Data type of the measure value: `DOUBLE`, `BIGINT`, `VARCHAR`, `BOOLEAN`, or `MULTI`. |
| `--query-string` | SQL query string sent to the `timestream-query` endpoint for reading data. |
| `--magnetic-store-write-properties` | Enables out-of-order writes to the magnetic store and sets an S3 bucket for rejected record reports. |
| `--tags` | Key-value metadata tags for cost allocation and resource organisation. |

## How to Run the Demo
```bash
cd services/03-database/timestream
bash demo.sh
```

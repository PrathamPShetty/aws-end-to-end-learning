# Amazon Redshift

## What is it?
Amazon Redshift is a fully managed, petabyte-scale cloud data warehouse designed for Online Analytical Processing (OLAP) and business intelligence workloads. It uses a columnar storage format and massively parallel processing (MPP) architecture to execute complex analytical SQL queries across billions of rows in seconds. Redshift is the right choice when you need to aggregate large volumes of historical data from multiple sources and run reporting or dashboarding queries that would overwhelm a transactional (OLTP) database. It integrates natively with S3, AWS Glue, and Redshift Spectrum, allowing you to query data directly in your data lake without loading it first.

## Key Concepts
- **Cluster** — The core resource; a set of one or more compute nodes coordinated by a leader node that parses queries and returns results.
- **Node Type** — Determines the compute and storage capacity per node: `dc2.large` (dense compute, SSD) or `ra3.xlplus` (managed storage, scales independently of compute).
- **Database** — A named logical container within a cluster that holds schemas, tables, views, and users, similar to a PostgreSQL database.
- **Cluster Subnet Group** — A set of VPC subnets across availability zones in which Redshift launches cluster nodes.
- **Cluster Parameter Group** — A collection of Redshift engine configuration parameters (e.g., `enable_user_activity_logging`, `query_group`) applied to a cluster.
- **Snapshot** — A point-in-time backup of the entire cluster stored in S3; can be automated (scheduled) or manual, and can be shared across AWS accounts.

## When to Use
- **Business intelligence and dashboards** — Power BI, Tableau, or QuickSight dashboards that aggregate sales, marketing, or operational data across months or years.
- **ETL pipeline destination** — Serve as the final storage layer for data pipelines that collect data from application databases, S3, and third-party SaaS tools.
- **Ad-hoc SQL analytics at scale** — Allow data analysts to write arbitrary SQL against hundreds of terabytes of structured data without worrying about query performance tuning.
- **Log and event analysis** — Ingest and query large volumes of application or clickstream logs to identify trends, anomalies, and user behaviour patterns.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create subnet group | `awslocal redshift create-cluster-subnet-group --cluster-subnet-group-name my-subnet-group --description "My group" --subnet-ids '["subnet-00000000"]'` |
| Create parameter group | `awslocal redshift create-cluster-parameter-group --parameter-group-name my-pg --parameter-group-family redshift-1.0 --description "My params"` |
| Create cluster | `awslocal redshift create-cluster --cluster-identifier demo-cluster --node-type dc2.large --master-username awsuser --master-user-password Test1234 --cluster-type single-node --db-name analytics` |
| List clusters | `awslocal redshift describe-clusters` |
| Describe one cluster | `awslocal redshift describe-clusters --cluster-identifier demo-cluster` |
| Create snapshot | `awslocal redshift create-cluster-snapshot --cluster-identifier demo-cluster --snapshot-identifier demo-snap1` |
| List snapshots | `awslocal redshift describe-cluster-snapshots --cluster-identifier demo-cluster` |
| Delete cluster | `awslocal redshift delete-cluster --cluster-identifier demo-cluster --skip-final-cluster-snapshot` |

## Example Walkthrough

1. **Create a cluster subnet group** to control the VPC placement of cluster nodes:
   ```bash
   awslocal redshift create-cluster-subnet-group \
     --cluster-subnet-group-name demo-subnet-group \
     --description "Demo Redshift subnet group" \
     --subnet-ids '["subnet-00000000"]'
   ```

2. **Create a cluster parameter group** using the `redshift-1.0` family:
   ```bash
   awslocal redshift create-cluster-parameter-group \
     --parameter-group-name demo-pg \
     --parameter-group-family redshift-1.0 \
     --description "Demo parameter group"
   ```

3. **Create a single-node Redshift cluster** with an `analytics` database:
   ```bash
   awslocal redshift create-cluster \
     --cluster-identifier demo-cluster \
     --node-type dc2.large \
     --master-username awsuser \
     --master-user-password Test1234 \
     --cluster-type single-node \
     --cluster-subnet-group-name demo-subnet-group \
     --cluster-parameter-group-name demo-pg \
     --db-name analytics
   ```

4. **Describe the cluster** to check its status and endpoint:
   ```bash
   awslocal redshift describe-clusters \
     --query 'Clusters[*].{ID:ClusterIdentifier,Status:ClusterStatus,NodeType:NodeType,DB:DBName}' \
     --output table
   ```

5. **Create a manual snapshot** before making schema changes:
   ```bash
   awslocal redshift create-cluster-snapshot \
     --cluster-identifier demo-cluster \
     --snapshot-identifier demo-cluster-snap1
   ```

6. **List available snapshots** to confirm the backup exists:
   ```bash
   awslocal redshift describe-cluster-snapshots \
     --cluster-identifier demo-cluster \
     --query 'Snapshots[*].{Snapshot:SnapshotIdentifier,Status:Status,Type:SnapshotType}' \
     --output table
   ```

7. **Delete the cluster** without retaining a final snapshot:
   ```bash
   awslocal redshift delete-cluster \
     --cluster-identifier demo-cluster \
     --skip-final-cluster-snapshot
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--cluster-identifier` | Unique name for the cluster (1–63 lowercase alphanumeric characters or hyphens). |
| `--node-type` | Instance type for each node: `dc2.large`, `dc2.8xlarge`, `ra3.xlplus`, `ra3.4xlarge`, etc. |
| `--cluster-type` | `single-node` or `multi-node`; multi-node requires `--number-of-nodes`. |
| `--number-of-nodes` | Number of compute nodes (2–128) for a multi-node cluster. |
| `--master-username` | Admin user name (1–128 alphanumeric characters, cannot be `awsuser` reserved names). |
| `--db-name` | Name of the initial database to create inside the cluster. |
| `--cluster-subnet-group-name` | VPC subnet group that determines in which subnets cluster nodes are launched. |
| `--cluster-parameter-group-name` | Parameter group to attach engine configuration settings. |
| `--encrypted` | Enables encryption at rest using AWS KMS. |
| `--skip-final-cluster-snapshot` | Delete the cluster without first creating a snapshot (use with caution). |
| `--snapshot-identifier` | Name for a manual snapshot created with `create-cluster-snapshot`. |

## How to Run the Demo
```bash
cd services/03-database/redshift
bash demo.sh
```

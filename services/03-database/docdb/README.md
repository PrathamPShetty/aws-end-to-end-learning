# Amazon DocumentDB (with MongoDB compatibility)

## What is it?
Amazon DocumentDB is a fully managed, MongoDB-compatible document database service that stores data as flexible JSON documents rather than rigid relational rows. It implements the MongoDB 4.0 and 5.0 wire protocol, meaning existing MongoDB drivers, tools, and application code work against DocumentDB with minimal or no changes. DocumentDB decouples storage from compute: all instances in a cluster share a single distributed storage volume that automatically grows in 10 GiB increments up to 128 TiB, and up to 15 read replicas can be added without replicating data. It is the right choice when you need MongoDB semantics, rich document queries, and the operational simplicity of a fully managed AWS service with automated backups, patching, and Multi-AZ failover.

## Key Concepts
- **DB Cluster** — The core resource; contains a single writer instance and up to 15 read replicas all sharing the same distributed storage volume.
- **DB Instance** — An individual compute node in the cluster; the writer handles all writes and the readers serve read queries.
- **Cluster Endpoint** — The DNS name for the writer instance; application code that writes to the database connects here.
- **Reader Endpoint** — A load-balanced DNS name that distributes read queries across all available reader instances.
- **DB Subnet Group** — A set of VPC subnets across multiple Availability Zones in which DocumentDB places cluster instances.
- **Cluster Parameter Group** — A collection of DocumentDB engine configuration parameters (e.g., `tls`, `audit_logs`, `profiler`) applied to a cluster.
- **Cluster Snapshot** — A point-in-time backup of the full cluster stored in S3; snapshots can be automated (daily) or manual.

## When to Use
- **Content management systems** — Store articles, pages, and media metadata as flexible JSON documents where the schema varies per content type.
- **User profiles and personalisation** — Keep user preference objects and activity histories as nested documents that are read and written atomically per user.
- **Product catalogues with variable attributes** — Model products where each category (electronics, clothing, food) has a different set of attributes without needing schema migrations.
- **Mobile and gaming backends** — Store player state, inventory, and progress as self-describing documents and query them with the MongoDB query language your developers already know.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create subnet group | `awslocal docdb create-db-subnet-group --db-subnet-group-name my-docdb-subnets --db-subnet-group-description "My group" --subnet-ids '["subnet-00000000"]'` |
| Create parameter group | `awslocal docdb create-db-cluster-parameter-group --db-cluster-parameter-group-name my-docdb-pg --db-parameter-group-family docdb5.0 --description "My params"` |
| Create cluster | `awslocal docdb create-db-cluster --db-cluster-identifier demo-docdb-cluster --engine docdb --master-username docadmin --master-user-password Secret123 --db-subnet-group-name my-docdb-subnets` |
| Create instance | `awslocal docdb create-db-instance --db-instance-identifier demo-docdb-instance --db-instance-class db.r5.large --engine docdb --db-cluster-identifier demo-docdb-cluster` |
| List clusters | `awslocal docdb describe-db-clusters` |
| Describe one cluster | `awslocal docdb describe-db-clusters --db-cluster-identifier demo-docdb-cluster` |
| Create cluster snapshot | `awslocal docdb create-db-cluster-snapshot --db-cluster-identifier demo-docdb-cluster --db-cluster-snapshot-identifier demo-snap1` |
| List snapshots | `awslocal docdb describe-db-cluster-snapshots --db-cluster-identifier demo-docdb-cluster` |
| Delete instance | `awslocal docdb delete-db-instance --db-instance-identifier demo-docdb-instance` |
| Delete cluster | `awslocal docdb delete-db-cluster --db-cluster-identifier demo-docdb-cluster --skip-final-snapshot` |

## Example Walkthrough

1. **Create a DB subnet group** to control which VPC subnets the cluster uses:
   ```bash
   awslocal docdb create-db-subnet-group \
     --db-subnet-group-name demo-docdb-subnets \
     --db-subnet-group-description "Demo DocumentDB subnet group" \
     --subnet-ids '["subnet-00000000"]'
   ```

2. **Create a cluster parameter group** for the `docdb5.0` engine family:
   ```bash
   awslocal docdb create-db-cluster-parameter-group \
     --db-cluster-parameter-group-name demo-docdb-pg \
     --db-parameter-group-family docdb5.0 \
     --description "Demo DocDB parameter group"
   ```

3. **Create the DocumentDB cluster** with an admin user and password:
   ```bash
   awslocal docdb create-db-cluster \
     --db-cluster-identifier demo-docdb-cluster \
     --engine docdb \
     --master-username docadmin \
     --master-user-password Secret123 \
     --db-subnet-group-name demo-docdb-subnets \
     --db-cluster-parameter-group-name demo-docdb-pg
   ```

4. **Create a writer instance** inside the cluster:
   ```bash
   awslocal docdb create-db-instance \
     --db-instance-identifier demo-docdb-instance \
     --db-instance-class db.r5.large \
     --engine docdb \
     --db-cluster-identifier demo-docdb-cluster
   ```

5. **Describe the cluster** to see its endpoint and current status:
   ```bash
   awslocal docdb describe-db-clusters \
     --db-cluster-identifier demo-docdb-cluster \
     --query 'DBClusters[*].{ID:DBClusterIdentifier,Engine:Engine,Status:Status,Endpoint:Endpoint}' \
     --output table
   ```

6. **Create a manual cluster snapshot** to back up your data:
   ```bash
   awslocal docdb create-db-cluster-snapshot \
     --db-cluster-identifier demo-docdb-cluster \
     --db-cluster-snapshot-identifier demo-docdb-snap1
   ```

7. **List available snapshots** to confirm the backup was created:
   ```bash
   awslocal docdb describe-db-cluster-snapshots \
     --db-cluster-identifier demo-docdb-cluster \
     --query 'DBClusterSnapshots[*].{Snapshot:DBClusterSnapshotIdentifier,Status:Status}' \
     --output table
   ```

8. **Clean up** by deleting the instance first, then the cluster:
   ```bash
   awslocal docdb delete-db-instance \
     --db-instance-identifier demo-docdb-instance
   awslocal docdb delete-db-cluster \
     --db-cluster-identifier demo-docdb-cluster \
     --skip-final-snapshot
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--db-cluster-identifier` | Unique name for the DocumentDB cluster (1–63 lowercase alphanumeric characters or hyphens). |
| `--db-instance-identifier` | Unique name for a single compute instance within the cluster. |
| `--engine` | Must be `docdb` for all DocumentDB resources. |
| `--db-instance-class` | Compute class for the instance (e.g., `db.r5.large`, `db.r6g.xlarge`). |
| `--master-username` | Admin user name for the database (1–63 alphanumeric characters). |
| `--master-user-password` | Password for the master user (must meet complexity requirements). |
| `--db-subnet-group-name` | VPC subnet group controlling where instances are placed. |
| `--db-cluster-parameter-group-name` | Parameter group for engine settings like TLS enforcement and profiling. |
| `--db-parameter-group-family` | Engine family used when creating a parameter group (e.g., `docdb4.0`, `docdb5.0`). |
| `--storage-encrypted` | Enables encryption at rest using KMS (strongly recommended for production). |
| `--deletion-protection` | Prevents the cluster from being accidentally deleted when set to `true`. |
| `--skip-final-snapshot` | Delete the cluster without creating a final snapshot (use with caution). |
| `--backup-retention-period` | Number of days (1–35) to retain automated daily backups. |

## How to Run the Demo
```bash
cd services/03-database/docdb
bash demo.sh
```

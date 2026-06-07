# Amazon RDS (Relational Database Service)

## What is it?
Amazon RDS is a fully managed relational database service that automates time-consuming administration tasks such as hardware provisioning, database setup, patching, and backups. It supports six popular database engines: MySQL, PostgreSQL, MariaDB, Oracle, Microsoft SQL Server, and Amazon Aurora. RDS is the right choice when your application requires ACID transactions, complex SQL queries, or an existing relational schema you want to migrate to the cloud with minimal changes. It handles Multi-AZ failover and read replicas automatically, giving you high availability and horizontal read scalability without manual configuration.

## Key Concepts
- **DB Instance** — The fundamental compute unit running your database engine; identified by a unique `DBInstanceIdentifier`.
- **DB Engine** — The database software running on the instance: `mysql`, `postgres`, `mariadb`, `oracle-ee`, `sqlserver-ex`, or `aurora`.
- **DB Subnet Group** — A collection of subnets (typically across multiple AZs) that RDS uses when creating a DB instance inside a VPC.
- **Parameter Group** — A collection of engine configuration values (e.g., `max_connections`, `innodb_buffer_pool_size`) applied to one or more DB instances.
- **DB Snapshot** — A point-in-time, user-initiated backup of a DB instance stored in S3; can be used to restore or copy an instance.
- **Multi-AZ Deployment** — A high-availability configuration where RDS synchronously replicates data to a standby instance in a different Availability Zone for automatic failover.

## When to Use
- **Web and mobile application backends** — Run MySQL or PostgreSQL for user accounts, orders, and transactional workloads that need ACID guarantees.
- **ERP / CRM systems** — Lift-and-shift Oracle or SQL Server workloads to the cloud while keeping existing application SQL unchanged.
- **Reporting databases with read replicas** — Offload heavy analytical queries to a read replica to keep the primary instance free for OLTP traffic.
- **SaaS multi-tenant applications** — Provision one isolated DB instance per customer tier and manage them uniformly through the RDS API.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create subnet group | `awslocal rds create-db-subnet-group --db-subnet-group-name my-subnet-group --db-subnet-group-description "My group" --subnet-ids '["subnet-00000000"]'` |
| Create DB instance | `awslocal rds create-db-instance --db-instance-identifier demo-mysql --db-instance-class db.t3.micro --engine mysql --master-username admin --master-user-password secret99 --allocated-storage 20` |
| List DB instances | `awslocal rds describe-db-instances` |
| Describe one instance | `awslocal rds describe-db-instances --db-instance-identifier demo-mysql` |
| Create snapshot | `awslocal rds create-db-snapshot --db-instance-identifier demo-mysql --db-snapshot-identifier demo-snap1` |
| List snapshots | `awslocal rds describe-db-snapshots --db-instance-identifier demo-mysql` |
| Modify instance | `awslocal rds modify-db-instance --db-instance-identifier demo-mysql --db-instance-class db.t3.small --apply-immediately` |
| Delete instance | `awslocal rds delete-db-instance --db-instance-identifier demo-mysql --skip-final-snapshot` |

## Example Walkthrough

1. **Create a DB subnet group** to place the instance inside a VPC:
   ```bash
   awslocal rds create-db-subnet-group \
     --db-subnet-group-name demo-subnet-group \
     --db-subnet-group-description "Demo subnet group" \
     --subnet-ids '["subnet-00000000"]'
   ```

2. **Create a MySQL DB instance** with 20 GB of allocated storage:
   ```bash
   awslocal rds create-db-instance \
     --db-instance-identifier demo-mysql \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --master-username admin \
     --master-user-password secret99 \
     --allocated-storage 20 \
     --no-multi-az \
     --db-subnet-group-name demo-subnet-group
   ```

3. **List all DB instances** and inspect their status:
   ```bash
   awslocal rds describe-db-instances \
     --query 'DBInstances[*].{ID:DBInstanceIdentifier,Engine:Engine,Status:DBInstanceStatus,Class:DBInstanceClass}' \
     --output table
   ```

4. **Create a manual snapshot** of the running instance:
   ```bash
   awslocal rds create-db-snapshot \
     --db-instance-identifier demo-mysql \
     --db-snapshot-identifier demo-mysql-snap1
   ```

5. **List available snapshots** to confirm the backup was created:
   ```bash
   awslocal rds describe-db-snapshots \
     --db-instance-identifier demo-mysql \
     --query 'DBSnapshots[*].{Snapshot:DBSnapshotIdentifier,Status:Status,Engine:Engine}' \
     --output table
   ```

6. **Modify the instance class** to scale up (applied immediately):
   ```bash
   awslocal rds modify-db-instance \
     --db-instance-identifier demo-mysql \
     --db-instance-class db.t3.small \
     --apply-immediately
   ```

7. **Delete the instance** without keeping a final snapshot:
   ```bash
   awslocal rds delete-db-instance \
     --db-instance-identifier demo-mysql \
     --skip-final-snapshot
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--db-instance-identifier` | Unique name for the DB instance (1–63 alphanumeric characters or hyphens). |
| `--db-instance-class` | Compute and memory capacity class (e.g., `db.t3.micro`, `db.m5.large`). |
| `--engine` | Database engine: `mysql`, `postgres`, `mariadb`, `oracle-ee`, `sqlserver-ex`. |
| `--allocated-storage` | Amount of storage in GiB (20–65536 depending on engine and class). |
| `--master-username` | Admin login name for the database master user. |
| `--master-user-password` | Password for the master user (min 8 characters). |
| `--multi-az` / `--no-multi-az` | Enables or disables synchronous standby replica in a second AZ. |
| `--db-subnet-group-name` | VPC subnet group that determines where the instance is placed. |
| `--publicly-accessible` | Whether the instance gets a public DNS endpoint (not recommended for production). |
| `--apply-immediately` | Apply `modify-db-instance` changes now instead of at the next maintenance window. |
| `--skip-final-snapshot` | Skip creating a final snapshot when deleting (use with caution in production). |

## How to Run the Demo
```bash
cd services/03-database/rds
bash demo.sh
```

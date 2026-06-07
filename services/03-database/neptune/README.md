# Amazon Neptune

## What is it?
Amazon Neptune is a fully managed graph database service optimised for storing and querying highly connected datasets. It supports two popular graph query languages: Apache TinkerPop Gremlin (property graphs) and SPARQL (RDF/knowledge graphs), letting you choose the model that best fits your data. Neptune automatically handles replication across three Availability Zones, continuous backups to S3, and failover in under 30 seconds, so you never have to manage graph database infrastructure. It is the right choice when relationships between data points are as important as the data itself — for example, social networks, recommendation engines, or fraud detection graphs with millions of edges.

## Key Concepts
- **DB Cluster** — The top-level Neptune resource; contains a primary writer instance and optionally up to 15 read replicas, all sharing the same distributed storage volume.
- **DB Instance** — A single compute node (writer or reader) within a cluster; the instance class (e.g., `db.r5.large`) determines its CPU and RAM.
- **Cluster Endpoint** — The DNS endpoint for the writer instance; your application sends all write queries here.
- **Reader Endpoint** — A load-balanced DNS endpoint that distributes read queries across all available read replicas.
- **Property Graph** — A graph model where nodes and edges can each have arbitrary key-value properties; queried with Gremlin.
- **RDF Graph** — A Resource Description Framework triple-store model (subject–predicate–object) used for knowledge graphs; queried with SPARQL.

## When to Use
- **Social networks** — Model users, friendships, and followers as nodes and edges, then traverse the graph to find mutual connections or suggested friends.
- **Recommendation engines** — Represent products, customers, and purchases as a graph and query for "customers who bought this also bought" patterns efficiently.
- **Fraud detection** — Link accounts, devices, IP addresses, and transactions to identify suspicious clusters or rings of fraudulent activity.
- **Knowledge graphs and identity resolution** — Build an enterprise knowledge graph that links entities (people, organisations, places) across multiple data sources for unified search.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create subnet group | `awslocal neptune create-db-subnet-group --db-subnet-group-name my-neptune-subnets --db-subnet-group-description "My group" --subnet-ids '["subnet-00000000"]'` |
| Create cluster | `awslocal neptune create-db-cluster --db-cluster-identifier demo-neptune-cluster --engine neptune --db-subnet-group-name my-neptune-subnets` |
| Create instance | `awslocal neptune create-db-instance --db-instance-identifier demo-neptune-instance --db-instance-class db.r5.large --engine neptune --db-cluster-identifier demo-neptune-cluster` |
| List clusters | `awslocal neptune describe-db-clusters` |
| Describe one cluster | `awslocal neptune describe-db-clusters --db-cluster-identifier demo-neptune-cluster` |
| List instances | `awslocal neptune describe-db-instances` |
| Create cluster snapshot | `awslocal neptune create-db-cluster-snapshot --db-cluster-identifier demo-neptune-cluster --db-cluster-snapshot-identifier demo-neptune-snap1` |
| Delete instance | `awslocal neptune delete-db-instance --db-instance-identifier demo-neptune-instance` |
| Delete cluster | `awslocal neptune delete-db-cluster --db-cluster-identifier demo-neptune-cluster --skip-final-snapshot` |

## Example Walkthrough

1. **Create a DB subnet group** to deploy the cluster inside a VPC:
   ```bash
   awslocal neptune create-db-subnet-group \
     --db-subnet-group-name demo-neptune-subnets \
     --db-subnet-group-description "Demo Neptune subnet group" \
     --subnet-ids '["subnet-00000000"]'
   ```

2. **Create a Neptune DB cluster** specifying the Neptune engine:
   ```bash
   awslocal neptune create-db-cluster \
     --db-cluster-identifier demo-neptune-cluster \
     --engine neptune \
     --db-subnet-group-name demo-neptune-subnets
   ```

3. **Create a DB instance** (writer) inside the cluster:
   ```bash
   awslocal neptune create-db-instance \
     --db-instance-identifier demo-neptune-instance \
     --db-instance-class db.r5.large \
     --engine neptune \
     --db-cluster-identifier demo-neptune-cluster
   ```

4. **Describe the cluster** to see its endpoint and status:
   ```bash
   awslocal neptune describe-db-clusters \
     --db-cluster-identifier demo-neptune-cluster \
     --query 'DBClusters[*].{ID:DBClusterIdentifier,Engine:Engine,Status:Status,Endpoint:Endpoint}' \
     --output table
   ```

5. **Describe the instance** to verify it is available:
   ```bash
   awslocal neptune describe-db-instances \
     --db-instance-identifier demo-neptune-instance \
     --query 'DBInstances[*].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Status:DBInstanceStatus}' \
     --output table
   ```

6. **Create a cluster snapshot** to capture the current graph state:
   ```bash
   awslocal neptune create-db-cluster-snapshot \
     --db-cluster-identifier demo-neptune-cluster \
     --db-cluster-snapshot-identifier demo-neptune-snap1
   ```

7. **Clean up** by deleting the instance first, then the cluster:
   ```bash
   awslocal neptune delete-db-instance \
     --db-instance-identifier demo-neptune-instance
   awslocal neptune delete-db-cluster \
     --db-cluster-identifier demo-neptune-cluster \
     --skip-final-snapshot
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--db-cluster-identifier` | Unique name for the Neptune cluster (1–63 alphanumeric characters or hyphens). |
| `--db-instance-identifier` | Unique name for a single compute instance within the cluster. |
| `--engine` | Must be `neptune` for all Neptune resources. |
| `--db-instance-class` | Compute class for the instance (e.g., `db.r5.large`, `db.r6g.xlarge`). |
| `--db-subnet-group-name` | VPC subnet group determining where cluster nodes are placed. |
| `--db-cluster-parameter-group-name` | Custom parameter group for graph engine settings (e.g., Neptune lab mode). |
| `--storage-encrypted` | Enables encryption at rest using KMS (recommended for production). |
| `--deletion-protection` | Prevents the cluster from being accidentally deleted when set to `true`. |
| `--skip-final-snapshot` | Skips taking a final snapshot when the cluster is deleted. |
| `--promotion-tier` | Priority (0–15) used to determine which read replica is promoted on failover. |

## How to Run the Demo
```bash
cd services/03-database/neptune
bash demo.sh
```

# Amazon ElastiCache

## What is it?
Amazon ElastiCache is a fully managed, in-memory caching service that supports two open-source engines: Redis and Memcached. It lets you deploy, run, and scale a cache in the cloud without managing the underlying infrastructure, patching, or cluster failover logic. ElastiCache is used to dramatically reduce database load and application latency by serving frequently accessed data from RAM rather than making round trips to a disk-based database. Redis mode additionally supports persistence, Pub/Sub messaging, sorted sets, and automatic Multi-AZ failover, making it suitable for use cases beyond pure caching.

## Key Concepts
- **Cache Cluster** — The primary compute resource; a single cluster can contain one or more cache nodes running Redis or Memcached.
- **Cache Node** — An individual in-memory instance within a cluster; the node type (e.g., `cache.t3.micro`) determines its RAM and network bandwidth.
- **Replication Group** — A Redis-specific logical grouping of one primary node and up to five read replicas, providing high availability and read scaling.
- **Cache Subnet Group** — A collection of VPC subnets in which ElastiCache places cluster nodes; required when deploying inside a VPC.
- **Cache Parameter Group** — A named set of engine-level configuration values (e.g., `maxmemory-policy`, `timeout`) applied to a cluster.
- **Snapshot** — A point-in-time backup of a Redis cluster's data; can be used to seed a new cluster or restore data.

## When to Use
- **Database query caching** — Cache the results of expensive SQL or DynamoDB queries in Redis to reduce latency from hundreds of milliseconds to under a millisecond.
- **Session store** — Store HTTP session data for stateless web servers so any server can pick up a user's session without a shared database call.
- **Real-time leaderboards** — Use Redis sorted sets (`ZADD`, `ZRANGE`) to maintain and query player scores in games without relying on a slow relational DB.
- **Rate limiting and throttling** — Use Redis atomic increment operations (`INCR`) and TTLs to enforce per-user API rate limits across a distributed fleet.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create parameter group | `awslocal elasticache create-cache-parameter-group --cache-parameter-group-name my-redis-params --cache-parameter-group-family redis7 --description "My Redis params"` |
| Create subnet group | `awslocal elasticache create-cache-subnet-group --cache-subnet-group-name my-subnet-group --cache-subnet-group-description "My group" --subnet-ids '["subnet-00000000"]'` |
| Create cluster | `awslocal elasticache create-cache-cluster --cache-cluster-id demo-redis --cache-node-type cache.t3.micro --engine redis --engine-version 7.0 --num-cache-nodes 1` |
| List clusters | `awslocal elasticache describe-cache-clusters` |
| Describe one cluster | `awslocal elasticache describe-cache-clusters --cache-cluster-id demo-redis` |
| List parameter groups | `awslocal elasticache describe-cache-parameter-groups` |
| Create snapshot | `awslocal elasticache create-snapshot --cache-cluster-id demo-redis --snapshot-name demo-snap1` |
| Delete cluster | `awslocal elasticache delete-cache-cluster --cache-cluster-id demo-redis` |

## Example Walkthrough

1. **Create a custom parameter group** for Redis 7 to hold tuning configuration:
   ```bash
   awslocal elasticache create-cache-parameter-group \
     --cache-parameter-group-name demo-redis-params \
     --cache-parameter-group-family redis7 \
     --description "Demo Redis parameter group"
   ```

2. **Create a cache subnet group** so the cluster can launch inside your VPC:
   ```bash
   awslocal elasticache create-cache-subnet-group \
     --cache-subnet-group-name demo-subnet-group \
     --cache-subnet-group-description "Demo subnet group" \
     --subnet-ids '["subnet-00000000"]'
   ```

3. **Create a single-node Redis cluster** using the parameter and subnet groups:
   ```bash
   awslocal elasticache create-cache-cluster \
     --cache-cluster-id demo-redis \
     --cache-node-type cache.t3.micro \
     --engine redis \
     --engine-version 7.0 \
     --num-cache-nodes 1 \
     --cache-parameter-group-name demo-redis-params \
     --cache-subnet-group-name demo-subnet-group
   ```

4. **Describe the cluster** to verify its status and endpoint address:
   ```bash
   awslocal elasticache describe-cache-clusters \
     --cache-cluster-id demo-redis \
     --query 'CacheClusters[*].{ID:CacheClusterId,Engine:Engine,Status:CacheClusterStatus,NodeType:CacheNodeType}' \
     --output table
   ```

5. **List all parameter groups** to confirm your custom group appears:
   ```bash
   awslocal elasticache describe-cache-parameter-groups \
     --query 'CacheParameterGroups[*].{Name:CacheParameterGroupName,Family:CacheParameterGroupFamily}' \
     --output table
   ```

6. **Create a snapshot** (Redis only) to back up cluster data:
   ```bash
   awslocal elasticache create-snapshot \
     --cache-cluster-id demo-redis \
     --snapshot-name demo-redis-snap1
   ```

7. **Delete the cluster** when finished:
   ```bash
   awslocal elasticache delete-cache-cluster --cache-cluster-id demo-redis
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--cache-cluster-id` | Unique identifier for the cache cluster (1–50 alphanumeric characters or hyphens). |
| `--engine` | Cache engine: `redis` or `memcached`. |
| `--engine-version` | Version of the cache engine (e.g., `7.0`, `6.2` for Redis). |
| `--cache-node-type` | Instance type determining RAM/CPU (e.g., `cache.t3.micro`, `cache.r6g.large`). |
| `--num-cache-nodes` | Number of nodes in the cluster (Memcached: 1–40; Redis: always 1 per cluster). |
| `--cache-parameter-group-name` | Name of the parameter group to associate with the cluster. |
| `--cache-subnet-group-name` | VPC subnet group that determines node placement. |
| `--cache-parameter-group-family` | Engine family used when creating a parameter group (e.g., `redis7`, `memcached1.6`). |
| `--automatic-failover-enabled` | Enables automatic failover for Multi-AZ Redis replication groups. |
| `--snapshot-retention-limit` | Number of days to retain automatic Redis snapshots (0 disables). |

## How to Run the Demo
```bash
cd services/03-database/elasticache
bash demo.sh
```

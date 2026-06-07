# Amazon Managed Streaming for Apache Kafka (MSK)

## What is it?
Amazon Managed Streaming for Apache Kafka (MSK) is a fully managed service that makes it easy to build and run applications that use Apache Kafka for real-time streaming data. MSK provisions, configures, and maintains the Kafka cluster, ZooKeeper (or KRaft) nodes, and the underlying infrastructure — you only deal with your topics, producers, and consumers. Because it runs native Kafka, any existing Kafka application, tool, or client library works without modification. MSK is the right choice when you need the full Kafka ecosystem (Kafka Streams, Kafka Connect, Schema Registry) or must maintain compatibility with existing Kafka-based systems.

## Key Concepts
- **Cluster** — The managed group of Kafka broker nodes. Identified by its ARN. You choose the number of brokers, Kafka version, and instance type.
- **Broker Node** — An individual Kafka server within the cluster. Each broker stores partitions and handles produce/consume requests. Spread across Availability Zones for HA.
- **Bootstrap Brokers** — The initial connection endpoints (host:port) your Kafka client uses to discover the rest of the cluster. Retrieved with `get-bootstrap-brokers`.
- **Topic** — A named, ordered, partitioned log of records. Producers write to topics; consumers subscribe to them.
- **Configuration** — A reusable set of Kafka server properties (e.g., `auto.create.topics.enable`, `log.retention.hours`) applied to a cluster.
- **MSK Connect** — A feature that runs Kafka Connect workers as a managed service, enabling connectors to stream data between Kafka and external systems like S3 or databases.

## When to Use
- **Migrate existing Kafka workloads to AWS** — lift-and-shift Kafka clusters without changing producers, consumers, or Kafka Streams applications.
- **High-throughput event streaming** — process millions of events per second from applications, databases (via CDC), or IoT devices with durable, replayable storage.
- **Stream processing pipelines** — pair MSK with Kafka Streams or AWS Glue Streaming ETL to transform and aggregate data in real time.
- **Decoupling large-scale microservices** — when you need more control over partitioning, consumer groups, and offset management than Kinesis provides.

## CLI Quick Reference (awslocal)

### Cluster operations

| Action | Command |
|---|---|
| Create cluster | `awslocal kafka create-cluster --cluster-name my-kafka-cluster --kafka-version "2.8.1" --number-of-broker-nodes 3 --broker-node-group-info '{"InstanceType":"kafka.m5.large","ClientSubnets":["subnet-aaa","subnet-bbb","subnet-ccc"],"StorageInfo":{"EbsStorageInfo":{"VolumeSize":100}}}'` |
| List clusters | `awslocal kafka list-clusters` |
| Describe cluster | `awslocal kafka describe-cluster --cluster-arn <ARN>` |
| Get bootstrap brokers | `awslocal kafka get-bootstrap-brokers --cluster-arn <ARN>` |
| Delete cluster | `awslocal kafka delete-cluster --cluster-arn <ARN>` |
| Update broker count | `awslocal kafka update-broker-count --cluster-arn <ARN> --current-version <VERSION> --target-number-of-broker-nodes 5` |

### Configuration operations

| Action | Command |
|---|---|
| Create configuration | `awslocal kafka create-configuration --name my-kafka-config --kafka-versions '["2.8.1"]' --server-properties "$(echo 'auto.create.topics.enable=true' \| base64)"` |
| List configurations | `awslocal kafka list-configurations` |
| Describe configuration | `awslocal kafka describe-configuration --arn <CONFIG_ARN>` |

### Monitoring operations

| Action | Command |
|---|---|
| List cluster operations | `awslocal kafka list-cluster-operations --cluster-arn <ARN>` |
| Describe cluster operation | `awslocal kafka describe-cluster-operation --cluster-operation-arn <OP_ARN>` |

## Example Walkthrough

1. **Create an MSK cluster with 2 broker nodes** — specify the Kafka version, instance type, subnets, and storage.
   ```bash
   CLUSTER_ARN=$(awslocal kafka create-cluster \
     --cluster-name demo-kafka-cluster \
     --kafka-version "2.8.1" \
     --number-of-broker-nodes 2 \
     --broker-node-group-info '{
       "InstanceType": "kafka.m5.large",
       "ClientSubnets": ["subnet-00000000", "subnet-11111111"],
       "StorageInfo": {"EbsStorageInfo": {"VolumeSize": 20}}
     }' \
     --output text --query 'ClusterArn')
   echo "Cluster ARN: $CLUSTER_ARN"
   ```

2. **Wait for the cluster to become ACTIVE** — MSK cluster creation takes several minutes in real AWS.
   ```bash
   until [ "$(awslocal kafka describe-cluster --cluster-arn "$CLUSTER_ARN" \
     --output text --query 'ClusterInfo.State')" = "ACTIVE" ]; do
     echo "Waiting..."; sleep 2
   done
   echo "Cluster is ACTIVE."
   ```

3. **Describe the cluster** — review the Kafka version, broker count, and current state.
   ```bash
   awslocal kafka describe-cluster --cluster-arn "$CLUSTER_ARN" \
     --output table \
     --query 'ClusterInfo.{Name:ClusterName,State:State,Version:CurrentBrokerSoftwareInfo.KafkaVersion,Brokers:NumberOfBrokerNodes}'
   ```

4. **Get the bootstrap broker endpoints** — these are the connection strings your Kafka clients need.
   ```bash
   awslocal kafka get-bootstrap-brokers --cluster-arn "$CLUSTER_ARN"
   ```

5. **Create a reusable MSK configuration** — set server properties like topic auto-creation and replication defaults.
   ```bash
   awslocal kafka create-configuration \
     --name demo-kafka-config \
     --kafka-versions '["2.8.1"]' \
     --server-properties "$(printf 'auto.create.topics.enable=true\ndefault.replication.factor=2\nmin.insync.replicas=1\nnum.partitions=3' | base64)"
   ```

6. **List all MSK clusters in the account** — see cluster names, ARNs, and states.
   ```bash
   awslocal kafka list-clusters --output table \
     --query 'ClusterInfoList[*].{Name:ClusterName,ARN:ClusterArn,State:State}'
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|---|---|
| `--cluster-name` | Unique name for the MSK cluster. |
| `--kafka-version` | Apache Kafka version to run (e.g., `2.6.0`, `2.8.1`, `3.4.0`). |
| `--number-of-broker-nodes` | Total broker count. Must be a multiple of the number of AZs (e.g., 3 for 3 AZs). |
| `--broker-node-group-info` | JSON block specifying `InstanceType`, `ClientSubnets` (one per AZ), and `StorageInfo`. |
| `InstanceType` | Kafka broker instance type: `kafka.t3.small`, `kafka.m5.large`, `kafka.m5.4xlarge`, etc. |
| `VolumeSize` | EBS volume size in GB per broker (min 1, max 16384). |
| `--server-properties` | Base64-encoded Kafka broker properties string for MSK configurations. |
| `--current-version` | The current semantic version of the cluster; required for `update-*` operations to prevent race conditions. |

## How to Run the Demo

```bash
cd services/04-messaging/msk
bash demo.sh
```

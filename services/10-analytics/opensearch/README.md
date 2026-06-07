# Amazon OpenSearch Service

## What is it?
Amazon OpenSearch Service is a managed service for deploying, operating, and scaling OpenSearch (and legacy Elasticsearch) clusters in AWS without managing servers. It provides a fully distributed search and analytics engine built on Apache Lucene, supporting full-text search, log analytics, real-time application monitoring, and vector search for AI workloads. Use it when you need sub-second search across large volumes of unstructured or semi-structured text, or when you want Kibana/OpenSearch Dashboards for interactive visualization. The service handles cluster provisioning, patching, backups, and multi-AZ replication automatically.

## Key Concepts
- **Domain** — The top-level resource in OpenSearch Service; a named, managed cluster that has its own endpoint, instance configuration, and storage settings.
- **Index** — A collection of JSON documents with a common schema; analogous to a database table. Documents in an index are distributed across shards.
- **Document** — A single JSON record stored in an index; identified by a unique `_id`.
- **Shard** — A horizontal partition of an index; OpenSearch distributes shards across nodes for parallelism and fault tolerance.
- **Mapping** — The schema definition for an index that specifies field names, data types (`text`, `keyword`, `date`, `integer`, `dense_vector`, etc.) and analyzer settings.
- **Query DSL** — OpenSearch's JSON-based query language used for full-text search (`match`, `multi_match`), filters (`term`, `range`), and aggregations (`terms`, `histogram`, `avg`).

## When to Use
- **Application search** — Add fast, relevance-ranked full-text search to an e-commerce site, documentation portal, or SaaS product over millions of records.
- **Log and event analytics** — Ingest logs from Kinesis Data Firehose or Logstash, then explore and alert on them using OpenSearch Dashboards (replaces the ELK stack).
- **Security analytics** — Correlate CloudTrail, VPC Flow Logs, and WAF logs for threat detection using OpenSearch's built-in Security Analytics plugin.
- **Vector / semantic search** — Store dense vector embeddings alongside metadata and run k-NN similarity searches for AI-powered recommendation or RAG pipelines.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create domain | `awslocal opensearch create-domain --domain-name my-domain --engine-version OpenSearch_2.5 --cluster-config InstanceType=t3.small.search,InstanceCount=1 --ebs-options EBSEnabled=true,VolumeType=gp2,VolumeSize=10` |
| List domains | `awslocal opensearch list-domain-names --query 'DomainNames[].DomainName'` |
| Describe domain | `awslocal opensearch describe-domain --domain-name my-domain` |
| Update domain config | `awslocal opensearch update-domain-config --domain-name my-domain --cluster-config InstanceCount=2` |
| Delete domain | `awslocal opensearch delete-domain --domain-name my-domain` |
| List versions | `awslocal opensearch list-versions --query 'Versions'` |
| Add tags | `awslocal opensearch add-tags --arn <DOMAIN_ARN> --tag-list Key=Env,Value=dev` |

> **Note:** Index, document, and search operations are performed via the OpenSearch REST API using `curl` against the domain endpoint, not through the AWS CLI.

## Example Walkthrough

1. **Create an OpenSearch domain** with a single `t3.small.search` node and 10 GB EBS storage:
   ```bash
   awslocal opensearch create-domain \
     --domain-name opensearch-demo \
     --engine-version "OpenSearch_2.5" \
     --cluster-config "InstanceType=t3.small.search,InstanceCount=1" \
     --ebs-options "EBSEnabled=true,VolumeType=gp2,VolumeSize=10"
   ```

2. **Describe the domain** to retrieve the endpoint and confirm it was created:
   ```bash
   awslocal opensearch describe-domain \
     --domain-name opensearch-demo \
     --query 'DomainStatus.{Domain:DomainName,Engine:EngineVersion,Endpoint:Endpoint,Created:Created}' \
     --output table
   ```

3. **Index a document** using the REST API (replace the endpoint with your domain's value):
   ```bash
   BASE_URL="http://localhost:4566/opensearch/us-east-1/opensearch-demo"
   curl -s -X PUT "${BASE_URL}/products/_doc/1" \
     -H 'Content-Type: application/json' \
     -d '{"name":"Widget","category":"hardware","price":19.99}' | python3 -m json.tool
   ```

4. **Index a second document** with a different category:
   ```bash
   curl -s -X PUT "${BASE_URL}/products/_doc/2" \
     -H 'Content-Type: application/json' \
     -d '{"name":"Gadget","category":"electronics","price":49.99}' | python3 -m json.tool
   ```

5. **Search for documents** matching a category using Query DSL:
   ```bash
   curl -s -X GET "${BASE_URL}/products/_search" \
     -H 'Content-Type: application/json' \
     -d '{"query":{"match":{"category":"electronics"}}}' | python3 -m json.tool
   ```

6. **Run an aggregation** to count documents per category:
   ```bash
   curl -s -X GET "${BASE_URL}/products/_search" \
     -H 'Content-Type: application/json' \
     -d '{
       "size": 0,
       "aggs": {
         "by_category": {"terms": {"field": "category.keyword"}}
       }
     }' | python3 -m json.tool
   ```

7. **List all domains** to confirm the domain is registered:
   ```bash
   awslocal opensearch list-domain-names \
     --query 'DomainNames[].DomainName' \
     --output table
   ```

8. **Delete the domain** when finished to free resources:
   ```bash
   awslocal opensearch delete-domain --domain-name opensearch-demo
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--domain-name` | Unique name for the OpenSearch domain (3-28 lowercase alphanumeric characters and hyphens). |
| `--engine-version` | OpenSearch or Elasticsearch version string, e.g. `OpenSearch_2.5` or `Elasticsearch_7.10`. |
| `--cluster-config` | Shorthand for instance type (`InstanceType`), count (`InstanceCount`), dedicated master (`DedicatedMasterEnabled`), and zone awareness settings. |
| `--ebs-options` | Storage configuration: `EBSEnabled`, `VolumeType` (`gp2`, `gp3`, `io1`), `VolumeSize` (GB), `Iops`. |
| `--access-policies` | JSON IAM resource-based policy controlling which principals can call the domain's REST endpoint. |
| `--encryption-at-rest-options` | Enables KMS encryption for data at rest: `Enabled=true,KmsKeyId=<key-id>`. |
| `--node-to-node-encryption-options` | Enables TLS encryption for traffic between cluster nodes: `Enabled=true`. |
| `--domain-endpoint-options` | Controls `EnforceHTTPS`, `TLSSecurityPolicy`, and `CustomEndpoint` settings. |
| `--auto-tune-options` | Enables OpenSearch Auto-Tune to automatically adjust JVM settings for performance. |
| `--tag-list` | Key-value tags applied to the domain ARN for cost allocation and access control. |

## How to Run the Demo
```bash
cd services/10-analytics/opensearch
bash demo.sh
```

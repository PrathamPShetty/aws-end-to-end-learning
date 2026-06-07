# Amazon DynamoDB

## What is it?
Amazon DynamoDB is a fully managed, serverless NoSQL key-value and document database designed to deliver single-digit millisecond performance at any scale. It automatically handles provisioning, patching, and replication across multiple Availability Zones, eliminating all database administration overhead. DynamoDB is ideal when you need a flexible schema, predictable low-latency reads and writes, and the ability to scale from zero to millions of requests per second without downtime. Its on-demand pricing model means you only pay for what you actually use.

## Key Concepts
- **Table** — The top-level container for data; equivalent to a relational table but schema-free (except for key attributes).
- **Item** — A single record in a table; equivalent to a row. Each item can have different attributes.
- **Partition Key (HASH)** — The primary key attribute used to distribute items across partitions. Must be unique per item when used alone.
- **Sort Key (RANGE)** — An optional second key that, combined with the partition key, forms a composite primary key allowing multiple items with the same partition key.
- **Global Secondary Index (GSI)** — An index with a different partition/sort key than the base table, enabling alternate query patterns.
- **Streams** — An ordered, time-limited log of item-level changes in a table; useful for triggering Lambda functions or replication.

## When to Use
- **E-commerce product catalogs** — Store millions of product records with variable attributes and serve them at millisecond latency.
- **Session and user profile storage** — Keep user session tokens or profile data that must be retrieved by a single key with extremely low latency.
- **Gaming leaderboards** — Use sort keys and GSIs to query top scores efficiently without full-table scans.
- **IoT device state tracking** — Ingest high-frequency writes from thousands of devices and query the latest state per device instantly.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create table | `awslocal dynamodb create-table --table-name Products --attribute-definitions AttributeName=productId,AttributeType=S AttributeName=category,AttributeType=S --key-schema AttributeName=productId,KeyType=HASH AttributeName=category,KeyType=RANGE --billing-mode PAY_PER_REQUEST` |
| List tables | `awslocal dynamodb list-tables` |
| Put item | `awslocal dynamodb put-item --table-name Products --item '{"productId":{"S":"p1"},"category":{"S":"electronics"},"name":{"S":"Laptop"}}'` |
| Get item | `awslocal dynamodb get-item --table-name Products --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}'` |
| Update item | `awslocal dynamodb update-item --table-name Products --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}' --update-expression "SET price = :p" --expression-attribute-values '{":p":{"N":"899"}}'` |
| Scan table | `awslocal dynamodb scan --table-name Products` |
| Delete item | `awslocal dynamodb delete-item --table-name Products --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}'` |
| Delete table | `awslocal dynamodb delete-table --table-name Products` |

## Example Walkthrough

1. **Create the Products table** with a composite key (partition key + sort key):
   ```bash
   awslocal dynamodb create-table \
     --table-name Products \
     --attribute-definitions \
       AttributeName=productId,AttributeType=S \
       AttributeName=category,AttributeType=S \
     --key-schema \
       AttributeName=productId,KeyType=HASH \
       AttributeName=category,KeyType=RANGE \
     --billing-mode PAY_PER_REQUEST
   ```

2. **Insert an item** representing a laptop in the electronics category:
   ```bash
   awslocal dynamodb put-item \
     --table-name Products \
     --item '{"productId":{"S":"p1"},"category":{"S":"electronics"},"name":{"S":"Laptop"},"price":{"N":"999"}}'
   ```

3. **Insert two more items** — a phone and a book:
   ```bash
   awslocal dynamodb put-item --table-name Products \
     --item '{"productId":{"S":"p2"},"category":{"S":"electronics"},"name":{"S":"Phone"},"price":{"N":"499"}}'
   awslocal dynamodb put-item --table-name Products \
     --item '{"productId":{"S":"p3"},"category":{"S":"books"},"name":{"S":"AWS Cookbook"},"price":{"N":"49"}}'
   ```

4. **Fetch a single item** by its full primary key:
   ```bash
   awslocal dynamodb get-item \
     --table-name Products \
     --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}' \
     --query 'Item.{id:productId.S,name:name.S,price:price.N}' \
     --output table
   ```

5. **Update the price** of the laptop using an update expression:
   ```bash
   awslocal dynamodb update-item \
     --table-name Products \
     --key '{"productId":{"S":"p1"},"category":{"S":"electronics"}}' \
     --update-expression "SET price = :p" \
     --expression-attribute-values '{":p":{"N":"899"}}' \
     --return-values UPDATED_NEW
   ```

6. **Scan all items** in the table and display them in a table format:
   ```bash
   awslocal dynamodb scan \
     --table-name Products \
     --query 'Items[*].{id:productId.S,name:name.S,price:price.N}' \
     --output table
   ```

7. **Delete the table** when finished:
   ```bash
   awslocal dynamodb delete-table --table-name Products
   ```

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--table-name` | Name of the DynamoDB table to operate on. |
| `--billing-mode` | `PAY_PER_REQUEST` (on-demand) or `PROVISIONED` (set read/write capacity units). |
| `--attribute-definitions` | Defines the data type (S=String, N=Number, B=Binary) for key attributes. |
| `--key-schema` | Specifies which attributes are HASH (partition) or RANGE (sort) keys. |
| `--update-expression` | Expression syntax for updating item attributes (e.g., `SET`, `REMOVE`, `ADD`). |
| `--expression-attribute-values` | Substitution values for expression placeholders (e.g., `:p`). |
| `--condition-expression` | Only performs write/delete if a condition evaluates to true (optimistic locking). |
| `--return-values` | Controls what is returned after a write: `NONE`, `ALL_OLD`, `UPDATED_NEW`, `ALL_NEW`. |
| `--filter-expression` | Filters scan/query results after DynamoDB reads them (does not reduce RCU consumption). |
| `--index-name` | Specifies a GSI or LSI name for a query operation. |

## How to Run the Demo
```bash
cd services/03-database/dynamodb
bash demo.sh
```

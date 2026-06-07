# Elastic Load Balancing (ELB)

## What is it?
Elastic Load Balancing automatically distributes incoming application traffic across multiple targets — such as EC2 instances, containers, or IP addresses — in one or more Availability Zones, ensuring no single backend is overwhelmed. It continuously monitors the health of registered targets and routes traffic only to healthy ones, making your application fault-tolerant and highly available. ELB offers three flavors: Application Load Balancer (ALB) for HTTP/HTTPS at Layer 7, Network Load Balancer (NLB) for TCP/UDP at Layer 4, and Gateway Load Balancer (GWLB) for third-party virtual appliances. Use it whenever you run more than one instance of a service and need traffic spread evenly, health-checked, and SSL-terminated in one place.

## Key Concepts
- **Load Balancer** — The entry point resource. Receives traffic and distributes it to registered targets. Types: `application` (ALB), `network` (NLB), `gateway` (GWLB).
- **Listener** — A process that checks for connection requests on a specified protocol and port (e.g., HTTP:80). Each listener has one or more rules.
- **Listener Rule** — A condition + action pair within a listener (e.g., "if path starts with `/api` then forward to the api-target-group"). The default rule is a catch-all.
- **Target Group** — A logical group of registered targets (instances, IPs, or Lambda functions). The load balancer forwards traffic to a target group; health checks run against it.
- **Target** — An individual backend endpoint (EC2 instance ID, IP address, or Lambda function ARN) registered inside a target group.
- **Health Check** — Periodic probe (HTTP, HTTPS, or TCP) sent to each target. Unhealthy targets are removed from rotation automatically.

## When to Use
- **Horizontal scaling** — Distribute traffic evenly across an Auto Scaling group of EC2 instances so adding more servers automatically receives traffic.
- **Zero-downtime deployments** — Deploy a new version by registering new instances in the target group and deregistering old ones; the ALB drains connections gracefully.
- **Path-based or host-based routing** — Use ALB listener rules to route `/api/*` to a backend service and `/static/*` to a different target group (or S3 via a redirect).
- **TLS termination** — Terminate HTTPS at the ALB using an ACM certificate so backend instances only need to handle plain HTTP, simplifying certificate management.

## CLI Quick Reference (awslocal)

### Load Balancer Operations
| Operation | Command |
|-----------|---------|
| Create ALB | `awslocal elbv2 create-load-balancer --name "my-alb" --type application --subnets subnet-aaa subnet-bbb` |
| List load balancers | `awslocal elbv2 describe-load-balancers` |
| Get specific LB | `awslocal elbv2 describe-load-balancers --load-balancer-arns <arn>` |
| Delete load balancer | `awslocal elbv2 delete-load-balancer --load-balancer-arn <arn>` |

### Target Group & Listener Operations
```bash
# Create target group
awslocal elbv2 create-target-group \
  --name "my-tg" \
  --protocol HTTP \
  --port 80 \
  --vpc-id <vpc-id> \
  --target-type instance

# Register targets
awslocal elbv2 register-targets \
  --target-group-arn <tg-arn> \
  --targets Id=i-0123456789abcdef0

# Create listener
awslocal elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTP \
  --port 80 \
  --default-actions "Type=forward,TargetGroupArn=<tg-arn>"

# Describe listeners
awslocal elbv2 describe-listeners --load-balancer-arn <alb-arn>

# Describe target health
awslocal elbv2 describe-target-health --target-group-arn <tg-arn>
```

## Example Walkthrough

1. **Create a VPC and two subnets (ALB requires at least two AZs)**
   ```bash
   VPC_ID=$(awslocal ec2 create-vpc --cidr-block 10.0.0.0/16 \
     --query 'Vpc.VpcId' --output text)
   SUBNET1=$(awslocal ec2 create-subnet --vpc-id "$VPC_ID" \
     --cidr-block 10.0.1.0/24 --availability-zone us-east-1a \
     --query 'Subnet.SubnetId' --output text)
   SUBNET2=$(awslocal ec2 create-subnet --vpc-id "$VPC_ID" \
     --cidr-block 10.0.2.0/24 --availability-zone us-east-1b \
     --query 'Subnet.SubnetId' --output text)
   echo "VPC: $VPC_ID  Subnets: $SUBNET1, $SUBNET2"
   ```
   Provisions the network infrastructure required for an Application Load Balancer.

2. **Create the Application Load Balancer**
   ```bash
   ALB_ARN=$(awslocal elbv2 create-load-balancer \
     --name "demo-alb" \
     --type application \
     --subnets "$SUBNET1" "$SUBNET2" \
     --query 'LoadBalancers[0].LoadBalancerArn' --output text)
   echo "ALB ARN: $ALB_ARN"
   ```
   Creates the ALB spanning both subnets for cross-AZ availability.

3. **Create a target group for backend instances**
   ```bash
   TG_ARN=$(awslocal elbv2 create-target-group \
     --name "demo-tg" \
     --protocol HTTP \
     --port 80 \
     --vpc-id "$VPC_ID" \
     --target-type instance \
     --query 'TargetGroups[0].TargetGroupArn' --output text)
   echo "Target Group ARN: $TG_ARN"
   ```
   Defines a pool of backend targets that will receive forwarded HTTP traffic on port 80.

4. **Create a listener on port 80 forwarding to the target group**
   ```bash
   awslocal elbv2 create-listener \
     --load-balancer-arn "$ALB_ARN" \
     --protocol HTTP \
     --port 80 \
     --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
     --query 'Listeners[0].{Port:Port,Protocol:Protocol}' \
     --output table
   ```
   Tells the ALB to accept HTTP connections on port 80 and forward them to the demo target group.

5. **Describe load balancers to confirm the state**
   ```bash
   awslocal elbv2 describe-load-balancers \
     --query 'LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
     --output table
   ```
   Lists all load balancers showing their DNS name and provisioning state (`active`, `provisioning`).

6. **Describe target groups**
   ```bash
   awslocal elbv2 describe-target-groups \
     --query 'TargetGroups[*].{Name:TargetGroupName,Protocol:Protocol,Port:Port,VPC:VpcId}' \
     --output table
   ```
   Confirms the target group exists and shows its protocol, port, and associated VPC.

7. **Check target health (after registering targets)**
   ```bash
   awslocal elbv2 describe-target-health \
     --target-group-arn "$TG_ARN"
   ```
   Displays the health status of each registered target (`healthy`, `unhealthy`, `unused`).

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--name` | Human-readable name for the load balancer or target group (max 32 chars) |
| `--type` | Load balancer type: `application` (ALB), `network` (NLB), `gateway` (GWLB) |
| `--subnets` | Space-separated subnet IDs (ALB requires subnets in at least 2 AZs) |
| `--protocol` | Listener/target group protocol: `HTTP`, `HTTPS`, `TCP`, `TLS`, `UDP` |
| `--port` | Port number the listener accepts connections on (e.g., `80`, `443`) |
| `--vpc-id` | VPC where the target group's targets reside |
| `--target-type` | How targets are identified: `instance`, `ip`, or `lambda` |
| `--default-actions` | Comma-separated action(s) for the listener's catch-all rule (e.g., `Type=forward,...`) |
| `--load-balancer-arn` | ARN of the load balancer (required for listener and describe operations) |
| `--target-group-arn` | ARN of the target group (required for listener rules and health checks) |
| `--health-check-path` | URL path used for HTTP health checks (default `/`) |
| `--health-check-interval-seconds` | Seconds between health check probes (default `30`) |

## How to Run the Demo
```bash
cd services/05-networking/elb
bash demo.sh
```

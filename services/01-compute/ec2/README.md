# Amazon EC2

## What is it?
Amazon Elastic Compute Cloud (EC2) provides resizable virtual machines — called instances — in the cloud, giving you full control over the operating system, networking, and software stack. You choose the instance type (CPU, memory, storage profile), launch it from an Amazon Machine Image (AMI), and connect to it just like a physical server. EC2 is the foundation of most traditional "lift-and-shift" workloads and is the right choice when you need persistent compute, custom runtimes, or workloads that run continuously. Unlike serverless options, EC2 gives you root-level access and the flexibility to run any software for any duration.

## Key Concepts
- **Instance** — a single running virtual machine with a specific CPU/memory/storage profile.
- **AMI (Amazon Machine Image)** — a snapshot/template used to launch instances; contains the OS and pre-installed software.
- **Instance Type** — the hardware profile (e.g. `t3.micro` = 2 vCPU / 1 GB RAM, `m6i.large` = 2 vCPU / 8 GB RAM).
- **Security Group** — a stateful virtual firewall that controls inbound and outbound traffic at the instance level.
- **Key Pair** — an SSH public/private key pair used to authenticate into Linux instances.
- **VPC / Subnet** — the virtual network and network segment where the instance lives; controls IP addressing and routing.
- **Elastic IP** — a static public IPv4 address you can attach to and detach from instances.

## When to Use
- **Web servers / application servers** — host a Node.js, Python, Java, or any other app server that must run 24/7 on a known OS.
- **Databases on custom hardware** — run databases that need specific OS tuning, storage configurations, or are not available as managed services.
- **Batch / HPC workloads** — run compute-intensive jobs (video encoding, scientific simulations) on high-CPU or GPU instances for as long as needed.
- **Lift-and-shift migrations** — move on-premises VMs to the cloud with minimal code changes by rehosting them as EC2 instances.

## CLI Quick Reference (awslocal)

### Create / Launch
```bash
# Create a VPC
awslocal ec2 create-vpc --cidr-block 10.0.0.0/16

# Create a subnet
awslocal ec2 create-subnet --vpc-id vpc-xxxxxxxx --cidr-block 10.0.1.0/24

# Create a security group
awslocal ec2 create-security-group \
  --group-name my-sg \
  --description "My security group" \
  --vpc-id vpc-xxxxxxxx

# Allow SSH inbound
awslocal ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create a key pair
awslocal ec2 create-key-pair --key-name my-key --query KeyMaterial --output text > my-key.pem

# Launch an instance
awslocal ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name my-key \
  --security-group-ids sg-xxxxxxxx \
  --subnet-id subnet-xxxxxxxx \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-server}]'
```

### List / Describe
```bash
# List all instances
awslocal ec2 describe-instances \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,IP:PublicIpAddress}' \
  --output table

# Filter by tag
awslocal ec2 describe-instances \
  --filters "Name=tag:Name,Values=my-server" "Name=instance-state-name,Values=running"

# List security groups
awslocal ec2 describe-security-groups --query 'SecurityGroups[].{ID:GroupId,Name:GroupName}'

# List key pairs
awslocal ec2 describe-key-pairs --output table
```

### Update (tags)
```bash
awslocal ec2 create-tags \
  --resources i-xxxxxxxxxxxxxxxx \
  --tags Key=Env,Value=production
```

### Stop / Start / Reboot
```bash
awslocal ec2 stop-instances   --instance-ids i-xxxxxxxxxxxxxxxx
awslocal ec2 start-instances  --instance-ids i-xxxxxxxxxxxxxxxx
awslocal ec2 reboot-instances --instance-ids i-xxxxxxxxxxxxxxxx
```

### Delete / Terminate
```bash
awslocal ec2 terminate-instances --instance-ids i-xxxxxxxxxxxxxxxx
awslocal ec2 delete-security-group --group-id sg-xxxxxxxx
awslocal ec2 delete-subnet --subnet-id subnet-xxxxxxxx
awslocal ec2 delete-vpc --vpc-id vpc-xxxxxxxx
```

## Example Walkthrough

1. **Create a VPC** — set up an isolated virtual network with a /16 CIDR block.
   ```bash
   VPC_ID=$(awslocal ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
     --query Vpc.VpcId --output text)
   echo "VPC: $VPC_ID"
   ```

2. **Create a subnet** — carve out a /24 segment inside the VPC for instances.
   ```bash
   SUBNET_ID=$(awslocal ec2 create-subnet \
     --vpc-id "$VPC_ID" \
     --cidr-block 10.0.1.0/24 \
     --query Subnet.SubnetId --output text)
   echo "Subnet: $SUBNET_ID"
   ```

3. **Create a security group and open SSH** — define the firewall rules for the instance.
   ```bash
   SG_ID=$(awslocal ec2 create-security-group \
     --group-name demo-sg \
     --description "Demo security group" \
     --vpc-id "$VPC_ID" \
     --query GroupId --output text)
   awslocal ec2 authorize-security-group-ingress \
     --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
   echo "Security group: $SG_ID"
   ```

4. **Create a key pair** — generate an SSH key and save the private key locally.
   ```bash
   awslocal ec2 create-key-pair \
     --key-name demo-key \
     --query KeyMaterial --output text > demo-key.pem
   chmod 400 demo-key.pem
   ```

5. **Launch an instance** — run a virtual machine using the VPC, subnet, SG, and key pair.
   ```bash
   INSTANCE_ID=$(awslocal ec2 run-instances \
     --image-id ami-0abcdef1234567890 \
     --instance-type t3.micro \
     --key-name demo-key \
     --security-group-ids "$SG_ID" \
     --subnet-id "$SUBNET_ID" \
     --count 1 \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=demo-instance}]' \
     --query 'Instances[0].InstanceId' --output text)
   echo "Instance: $INSTANCE_ID"
   ```

6. **Describe the instance** — verify it launched and check its state.
   ```bash
   awslocal ec2 describe-instances \
     --instance-ids "$INSTANCE_ID" \
     --query 'Reservations[0].Instances[0].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
     --output table
   ```

7. **Stop the instance** — shut it down without deleting it; you can start it again later.
   ```bash
   awslocal ec2 stop-instances --instance-ids "$INSTANCE_ID"
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--image-id` | AMI ID to boot from | `ami-0abcdef1234567890` |
| `--instance-type` | CPU/memory profile | `t3.micro`, `m6i.large`, `c6g.xlarge` |
| `--count` | Number of instances to launch | `1` |
| `--key-name` | SSH key pair name for login | `my-key` |
| `--security-group-ids` | Firewall rules to attach | `sg-xxxxxxxx` |
| `--subnet-id` | Subnet (and therefore VPC) to place instance in | `subnet-xxxxxxxx` |
| `--tag-specifications` | Tags applied at launch | `ResourceType=instance,Tags=[{Key=Name,Value=web}]` |
| `--user-data` | Bootstrap script run on first boot | `file://init.sh` |
| `--iam-instance-profile` | IAM role attached to the instance | `Name=my-instance-profile` |
| `--cidr-block` | IP range for VPC or subnet | `10.0.0.0/16` |
| `--filters` | Filter describe results by attribute or tag | `Name=instance-state-name,Values=running` |

## How to Run the Demo

```bash
cd services/01-compute/ec2
bash demo.sh
```

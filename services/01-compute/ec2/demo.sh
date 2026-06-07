#!/bin/bash
# ══════════════════════════════════════════════════════
#  EC2 Demo — VPC, security group, key pair, instance
#  Endpoint: LocalStack @ localhost:4566
# ══════════════════════════════════════════════════════
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

AWS="awslocal"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   EC2 Demo                           ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── VPC ───────────────────────────────────────────────
echo "▶ Creating VPC..."
VPC_ID=$($AWS ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --query Vpc.VpcId --output text)
$AWS ec2 create-tags --resources "$VPC_ID" \
  --tags Key=Name,Value=demo-vpc > /dev/null
echo "  ✓ VPC: $VPC_ID"

# ── Subnet ────────────────────────────────────────────
echo "▶ Creating subnet..."
SUBNET_ID=$($AWS ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --query Subnet.SubnetId --output text)
echo "  ✓ Subnet: $SUBNET_ID"

# ── Security Group ─────────────────────────────────────
echo "▶ Creating security group..."
SG_ID=$($AWS ec2 create-security-group \
  --group-name demo-sg \
  --description "Demo security group" \
  --vpc-id "$VPC_ID" \
  --query GroupId --output text)
$AWS ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
echo "  ✓ Security group: $SG_ID (SSH/22 open)"

# ── Key Pair ───────────────────────────────────────────
echo "▶ Creating key pair..."
$AWS ec2 delete-key-pair --key-name demo-key > /dev/null 2>&1 || true
$AWS ec2 create-key-pair \
  --key-name demo-key \
  --query KeyMaterial --output text > /dev/null
echo "  ✓ Key pair: demo-key"

# ── Run Instance ───────────────────────────────────────
echo "▶ Launching EC2 instance..."
INSTANCE_ID=$($AWS ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name demo-key \
  --security-group-ids "$SG_ID" \
  --subnet-id "$SUBNET_ID" \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=demo-instance}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  ✓ Instance: $INSTANCE_ID"

# ── Describe Instances ─────────────────────────────────
echo "▶ Listing instances..."
$AWS ec2 describe-instances \
  --filters "Name=tag:Name,Values=demo-instance" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
  --output table

# ── Stop Instance ──────────────────────────────────────
echo "▶ Stopping instance..."
$AWS ec2 stop-instances --instance-ids "$INSTANCE_ID" \
  --query 'StoppingInstances[0].CurrentState.Name' --output text
echo "  ✓ Stop requested"

echo ""
echo "  ✅  EC2 demo complete"
echo ""

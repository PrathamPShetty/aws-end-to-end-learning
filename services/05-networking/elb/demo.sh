#!/bin/bash
# =============================================================
# Service: ELB (Elastic Load Balancing) — Application LB (ALBv2)
# Purpose: Create ALB, target group, listener, and inspect state
# =============================================================
set -e

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo ">>> [ELB] Creating VPC and subnets for ALB"
VPC_ID=$(awslocal ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
SUBNET1=$(awslocal ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
SUBNET2=$(awslocal ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
echo "VPC: $VPC_ID | Subnets: $SUBNET1, $SUBNET2"

echo ">>> [ELB] Creating Application Load Balancer"
ALB_ARN=$(awslocal elbv2 create-load-balancer \
  --name "demo-alb" \
  --type application \
  --subnets "$SUBNET1" "$SUBNET2" \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "ALB ARN: $ALB_ARN"

echo ">>> [ELB] Creating target group (HTTP:80)"
TG_ARN=$(awslocal elbv2 create-target-group \
  --name "demo-tg" \
  --protocol HTTP \
  --port 80 \
  --vpc-id "$VPC_ID" \
  --target-type instance \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "Target Group ARN: $TG_ARN"

echo ">>> [ELB] Creating listener on port 80 -> target group"
awslocal elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --query 'Listeners[0].{Port:Port,Protocol:Protocol,ARN:ListenerArn}' \
  --output table

echo ">>> [ELB] Describing load balancers"
awslocal elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
  --output table

echo ">>> [ELB] Describing target groups"
awslocal elbv2 describe-target-groups \
  --query 'TargetGroups[*].{Name:TargetGroupName,Protocol:Protocol,Port:Port}' \
  --output table

echo "Done."

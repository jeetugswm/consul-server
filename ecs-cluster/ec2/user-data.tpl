#!/bin/bash

echo ECS_CLUSTER=${ecs-cluster-name} > /etc/ecs/ecs.config


# Install Docker
sudo su
yum update -y
yum install -y docker
service docker start

# Get my IP and the IP of any node in the server cluster.
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
NODE_ID=$(aws --region="ap-southeast-2" autoscaling describe-auto-scaling-groups --auto-scaling-group-name "consul-asg" | grep InstanceId | cut -d '"' -f4 | head -1)
NODE_IP=$(aws --region="ap-southeast-2" ec2 describe-instances --query="Reservations[].Instances[].[PrivateIpAddress]" --output="text" --instance-ids="$NODE_ID")

# Run the consul agent. 
docker run -d --net=host consul agent -bind="$IP" -join=$NODE_IP

# Run registrator - any Docker images will then be auto registered.
docker run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://localhost:8500

# Run the example microservice - registrator will take care of letting consul know.
docker run -d -p 80:4567 jitgswm/portal
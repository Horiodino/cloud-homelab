# Create VPC (Virtual Private Cloud)
echo
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=kubernetes-the-hard-way
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'

echo "VPC created successfully"

# the above command will return the VPC ID, which we will use in the next command to create subnets
# vpc is nothing but a isolated network in AWS like if you heard about azure resource group, it is same as that

# Create Subnets

echo "Creating Subnets"
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.1.0/24 \
  --output text --query 'Subnet.SubnetId')
aws ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=kubernetes

echo "Subnet created successfully"
# the above script will create a subnet in the VPC we created in the previous step
#  a subnet is used to divide the network into smaller networks. 
# the cidr block is the ip range of the subnet, which is private ip range
# and lastly -- output text --query 'Subnet.SubnetId' will return the subnet id, which we will use in the next command

# Create Internet Gateway

echo "Creating Internet Gateway"
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 create-tags --resources ${INTERNET_GATEWAY_ID} --tags Key=Name,Value=kubernetes
aws ec2 attach-internet-gateway --internet-gateway-id ${INTERNET_GATEWAY_ID} --vpc-id ${VPC_ID}

echo "Internet Gateway created successfully"
# the above script will create a internet gateway and attach it to the VPC we created in the previous step
# a internet gateway is used to connect the VPC to the internet and allow internet access to the resources in the VPC

# Create Route Table

echo "Creating Route Table"

ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id ${VPC_ID} --output text --query 'RouteTable.RouteTableId')
aws ec2 create-tags --resources ${ROUTE_TABLE_ID} --tags Key=Name,Value=kubernetes
aws ec2 associate-route-table --route-table-id ${ROUTE_TABLE_ID} --subnet-id ${SUBNET_ID}
aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${INTERNET_GATEWAY_ID}


echo "Route Table created successfully"
# the above script will create a route table and associate it with the subnet we created in the previous step
# a route table is used to route the traffic from the subnet to the internet gateway
# the destination cidr block is the ip range of the traffic that will be routed to the internet gateway

# Create Firewall 

echo "Creating Firewall"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name kubernetes \
  --description "Kubernetes security group" \
  --vpc-id ${VPC_ID} \
  --output text --query 'GroupId')
aws ec2 create-tags --resources ${SECURITY_GROUP_ID} --tags Key=Name,Value=kubernetes
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.200.0.0/16
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 6443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol icmp --port -1 --cidr 0.0.0.0/0

echo "Firewall created successfully"
# the above script will create a firewall and allow all traffic from the subnet to the firewall
# a firewall is used to control the traffic that is allowed to enter or leave the subnet
# the cidr block is the ip range of the traffic that will be allowed to enter or leave the subnet

# Create Load Balancer

echo "Creating Load Balancer"
  LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name kubernetes \
    --subnets ${SUBNET_ID} \
    --scheme internet-facing \
    --type network \
    --output text --query 'LoadBalancers[].LoadBalancerArn')
  TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name kubernetes \
    --protocol TCP \
    --port 6443 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --output text --query 'TargetGroups[].TargetGroupArn')
  aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=10.0.1.1{0,1,2}
  aws elbv2 create-listener \
    --load-balancer-arn ${LOAD_BALANCER_ARN} \
    --protocol TCP \
    --port 443 \
    --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} \
    --output text --query 'Listeners[].ListenerArn'


echo "Load Balancer created successfully"
# Create Public IP

echo "Creating Public IP"
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')
communication

echo "Public IP created successfully"
# the above script will create a load balancer and a target group and register the instances to the target group


# Create Kubernetes Instances
# Instance image
echo "Creating Instance Image"
IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 \
  --output json \
  --filters \
  'Name=root-device-type,Values=ebs' \
  'Name=architecture,Values=x86_64' \
  'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*' \
  | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')


echo "Instance Image created successfully"
# the above script will get the latest ubuntu image for the instances

# SSH Key Pair 
echo "Creating SSH Key Pair"
aws ec2 create-key-pair --key-name kubernetes --output text --query 'KeyMaterial' > kubernetes.id_rsa
chmod 600 kubernetes.id_rsa

echo "SSH Key Pair created successfully"

# the above script will create a ssh key pair for the instances
# ssh key pair is used to connect to the instances using ssh
# so we can run the commands on the instances


#  Create Instances 

#  we will be using the t2.micro instances for the kubernetes cluster as its free tier eligible

# Controle Plane Instances
echo "Creating Control Plane Instances"
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
   --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t2.micro \
     --private-ip-address 10.0.1.1${i} \
    --user-data "name=controller-${i}" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings='[
      {
        "DeviceName": "/dev/sda1",
        "Ebs": {
          "VolumeSize": 20
        }
      }
    ]' \

     --output text --query 'Instances[].InstanceId')
     aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=controller-${i}"
  echo "controller-${i} created "
done

echo "All Control Plane Instances created successfully"

# this for loop is used to create the instances
# the --user-data "name=controller-${i}" is used to set the hostname of the instance
# the --block-device-mappings is used to set the size of the root volume of the instance to 20GB
# the root volume is the volume where the operating system is installed like your hard disk in your computer
# we set the size of the root volume to 20GB as the default size is 8GB and we need more space for the kubernetes cluster


# Worker Instances

echo "Creating Worker Instances"
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t2.micro \
     --private-ip-address 10.0.1.2${i} \
    --user-data "name=worker-${i}|pod-cidr=10.200.${i}.0/24" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings='[
      {
        "DeviceName": "/dev/sda1",
        "Ebs": {
          "VolumeSize": 20
        }
      }
    ]' \
     --output text --query 'Instances[].InstanceId')
     aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
     aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=worker-${i}"
  echo "worker-${i} created"
done


echo "All Worker Instances created successfully"
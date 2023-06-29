VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=kubernetes-the-hard-way
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'


// the above command will return the VPC ID, which we will use in the next command to create subnets
// vpc is nothing but a isolated network in AWS like if you heard about azure resource group, it is same as that

// Create Subnets
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.1.0/24 \
  --output text --query 'Subnet.SubnetId')
aws ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=kubernetes

// the above script will create a subnet in the VPC we created in the previous step
//  a subnet is used to divide the network into smaller networks. 
// the cidr block is the ip range of the subnet, which is private ip range
// and lastly -- output text --query 'Subnet.SubnetId' will return the subnet id, which we will use in the next command



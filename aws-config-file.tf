# creating my AWS VPC with a publick and private subnet, appropriate tables, an Internet Gateway, a NAT Gateway,
#and an EC2 instance in the public subnet. Config  is modular and will be expanded to include more complex infrastucture
# as needed.

# Componenets Needed:
# Terraform Installed: (Ensure you have Terraform installed on my local machine).
# AWS CLI Installed and Configured: (Install the AWS CLI and configure it with your AWS credentials using aws configure.)
# IAM User with Proper Permissions: (Ensure your AWS IAM user has the necessary permissions to create and destroy resources)

###########-------------------------------------------------------------------------#######################
## Step1: - Creating my Directory Structure for my project. 'main.tf' ##

"main.terraform {
  required_version = ">= 0.12"    #Main configuration file
}
"

###########-------------------------------------------------------------------------#######################
## Step2: Defining my input variables. 'variable.ft'##

 variable "region" {
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnets"
  default     = "us-west-2a"
}

variable "instance_type" {
  description = "The type of instance to create"
  default     = "t2.micro"
}

###########-------------------------------------------------------------------------#######################
## Step3:  Defining my AWS Resources (main.tf)##

provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MainVPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "MainInternetGateway"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "PublicSubnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "PrivateSubnet"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "NATGateway"
  }
}

# Create Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate Route Table with Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MainSecurityGroup"
  }
}

# Launch EC2 Instance in Public Subnet
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.main.name]

  tags = {
    Name = "PublicInstance"
  }
}

###########-------------------------------------------------------------------------#######################
## Step4: Defining my Output Variables (outputs.tf)##

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}

output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.example.id
}


###########-------------------------------------------------------------------------#######################
## Running my configuration##

# Initialize Terraform:
terraform init

# Infrastructure Planning:
terraform plan

# Applying the Configuration:
terraform apply #(Type 'yes' to confirm When prompted, and proceed)

# Verifying Output:
# After the apply command completes, you can check the AWS Management Console to verify that the resources 
# have been created as expected. 
# The output in your terminal will also provide the IDs of the created resources.
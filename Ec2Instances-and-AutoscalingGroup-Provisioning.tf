# Create Directory Structure ()
# Create a directory for my Terraform project and navigate into it. 
# Inside this directory, create the following files:

###########-------------------------------------------------------------------------#######################
## Step1: - Creating Main Configuration File##

"main.terraform {
  required_version = ">= 0.12"
}
"
###########-------------------------------------------------------------------------#######################
 ## Step2: Defining Input Variables (variables.tf)##

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

variable "desired_capacity" {
  description = "Desired number of instances in the auto-scaling group"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the auto-scaling group"
  default     = 5
}

variable "min_size" {
  description = "Minimum number of instances in the auto-scaling group"
  default     = 1
}

###########-------------------------------------------------------------------------#######################
## Step3: Defining AWS Resources (main.tf)##

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

# Create Launch Template
resource "aws_launch_template" "app" {
  name_prefix = "app-launch-template-"
  
  image_id = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.main.id]
    subnet_id = aws_subnet.private.id
  }

  tags = {
    Name = "AppInstance"
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = [aws_subnet.private.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "AppInstance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Auto Scaling Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300

  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300

  autoscaling_group_name = aws_autoscaling_group.app.name
}

###########-------------------------------------------------------------------------#######################
## Defining Output Variables (outputs.tf)##

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

output "autoscaling_group_id" {
  description = "The ID of the auto-scaling group"
  value       = aws_autoscaling_group.app.id
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.app.id
}

## Running my Configuration#
#Initialize Terraform:
terraform init

# Plan the Infrastructure:
terraform plan

# Apply the Configuration:  
terraform apply     #Type yes to confirm When prompted and proceed.

# Verify the Output:
# After the apply command completes, I can check the AWS Management Console to verify that the resources have been created as expected. 
# The output in my terminal will also provide the IDs of the created resources.


# Terraform Installed: Ensure my have Terraform is installed on my local machine.
# AWS CLI Installed and Configured: Install the AWS CLI and configure it with my AWS credentials using aws configure.
# IAM User with Proper Permissions: Ensure my AWS IAM user has the necessary permissions to create and destroy resources.

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

variable "vpc_id" {
  description = "The ID of the VPC where RDS will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "db_instance_identifier" {
  description = "The identifier for the RDS instance"
  default     = "my-rds-instance"
}

variable "db_name" {
  description = "The name of the database to create"
  default     = "mydatabase"
}

variable "db_username" {
  description = "The master username for the database"
  default     = "admin"
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance class of the RDS instance"
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes"
  default     = 20
}

variable "backup_retention_period" {
  description = "The number of days to retain backups"
  default     = 7
}

###########-------------------------------------------------------------------------#######################
# Step3: Define AWS Resources (main.tf)

provider "aws" {
  region = var.region
}

# Create Security Group for RDS
resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
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
    Name = "rds-security-group"
  }
}

# Create Subnet Group for RDS
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "rds-subnet-group"
  }
}

# Create RDS Instance
resource "aws_db_instance" "rds" {
  identifier              = var.db_instance_identifier
  allocated_storage       = var.db_allocated_storage
  instance_class          = var.db_instance_class
  engine                  = "postgres"
  engine_version          = "13.4"
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  multi_az                = true
  storage_encrypted       = true
  backup_retention_period = var.backup_retention_period
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  tags = {
    Name = "my-rds-instance"
  }

  # Enable automated backups
  backup_window           = "07:00-09:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"
}

###########-------------------------------------------------------------------------#######################
# Step4: Define Output Variables (outputs.tf)

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.rds.endpoint
}

output "rds_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = aws_db_instance.rds.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds.id
}

###########-------------------------------------------------------------------------#######################
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

# Additional Comment
# Database Credentials Management: For better security, I have to consider managing my database credentials using AWS Secrets Manager or 
# AWS Systems Manager Parameter Store.
# Monitoring and Alerts: Set up CloudWatch alarms and SNS notifications to monitor the health and performance of my RDS instance.
# Parameter Groups: Customize my RDS instance by creating and associating parameter groups that define database engine settings
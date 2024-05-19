###########-------------------------------------------------------------------------#######################
## Step1: - Creating Main Configuration File##

"main.terraform {
  required_version = ">= 0.12"
}
"
###########-------------------------------------------------------------------------#######################
 ## Step2: Defining Input Variables (variables.tf)##

 variable "role_name" {
  description = "The name of the IAM role"
}

variable "policy_name" {
  description = "The name of the IAM policy"
}

variable "policy_description" {
  description = "Description for the IAM policy"
}

variable "policy_document" {
  description = "IAM policy document in JSON format"
}

###########-------------------------------------------------------------------------#######################
# Step3: Define AWS Resources (main.tf)  - In this example, we'll create an IAM role and attach a policy to it.

provider "aws" {
  region = "us-west-2"  # Update with my desired region
}

# Define IAM Role
resource "aws_iam_role" "example_role" {
  name               = var.role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Define IAM Policy
resource "aws_iam_policy" "example_policy" {
  name        = var.policy_name
  description = var.policy_description
  policy      = var.policy_document
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = aws_iam_policy.example_policy.arn
}

###########-------------------------------------------------------------------------#######################
# Step4: Define Output Variables (outputs.tf)

output "role_arn" {
  description = "The ARN of the created IAM role"
  value       = aws_iam_role.example_role.arn
}

output "policy_arn" {
  description = "The ARN of the created IAM policy"
  value       = aws_iam_policy.example_policy.arn
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

# Additional Comments
# Policy Document Format: Ensure that the policy_document variable in my variables.tf file contains a valid IAM policy document in JSON format.
# IAM Role Usage: Modify the assume_role_policy in the IAM role resource block according to the service or entity that needs to assume this role. In this example, it's configured for EC2 instances.
# Granular Permissions: Craft IAM policies with the principle of least privilege to grant only the necessary permissions to resources and actions.
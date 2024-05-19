###########-------------------------------------------------------------------------#######################
## Step1: - Creating Main Configuration File##

"main.terraform {
  required_version = ">= 0.12"
}
"
###########-------------------------------------------------------------------------#######################
 ## Step2: Defining Input Variables (variables.tf)##

 variable "alarm_name" {
  description = "The name of the CloudWatch Alarm"
}

variable "metric_name" {
  description = "The name of the CloudWatch metric to monitor"
}

variable "namespace" {
  description = "The namespace of the CloudWatch metric"
}

variable "comparison_operator" {
  description = "The comparison operator for the CloudWatch Alarm"
  default     = "GreaterThanOrEqualToThreshold"
}

variable "threshold" {
  description = "The threshold value for triggering the CloudWatch Alarm"
  default     = 90
}

variable "evaluation_periods" {
  description = "The number of evaluation periods for the CloudWatch Alarm"
  default     = 2
}

variable "logging_policy_name" {
  description = "The name of the CloudWatch Logs IAM policy"
}

variable "log_group_name" {
  description = "The name of the CloudWatch Logs log group"
}

###########-------------------------------------------------------------------------#######################
# Step3: Define AWS Resources (main.tf)

provider "aws" {
  region = "us-west-2"  # Update with my desired region
}

# Create CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "example_alarm" {
  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  statistic           = "Average"
  threshold           = var.threshold

  dimensions = {
    InstanceId = "i-12345678"  # Update with my instance ID or relevant dimension
  }

  alarm_actions = ["arn:aws:sns:us-west-2:123456789012:my-sns-topic"]  # Update with my SNS topic ARN
}

# Define CloudWatch Logs IAM Policy
resource "aws_iam_policy" "logging_policy" {
  name        = var.logging_policy_name
  description = "IAM policy for CloudWatch Logs"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach IAM Policy to IAM Role or User (Update with my target)
resource "aws_iam_policy_attachment" "logging_policy_attachment" {
  name       = "CloudWatchLogsPolicyAttachment"
  roles      = ["arn:aws:iam::123456789012:role/my-iam-role"]  # Update with my IAM role ARN
  policy_arn = aws_iam_policy.logging_policy.arn
}

# Create CloudWatch Logs Group
resource "aws_cloudwatch_log_group" "example_log_group" {
  name              = var.log_group_name
  retention_in_days = 7  # Adjust retention as needed
}

###########-------------------------------------------------------------------------#######################
# Step4: Define Output Variables (outputs.tf)

output "cloudwatch_alarm_arn" {
  description = "The ARN of the created CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.example_alarm.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Logs log group"
  value       = aws_cloudwatch_log_group.example_log_group.name
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
# After the apply command completes, you can check the AWS Management Console to verify that the CloudWatch Alarm 
# and CloudWatch Logs log group have been created as expected. The output in my terminal will also provide the ARN 
# of the created CloudWatch Alarm and the name of the CloudWatch Logs log group.

# Additional Comments:
# Adjustments: Modify the variables and resources as per my specific monitoring and logging requirements.
# Integration with Resources: Ensure that the dimensions and alarm actions in the CloudWatch Alarm resource match my target resources and actions.
# IAM Policies: Customize IAM policies according to the specific permissions needed for CloudWatch Logs.
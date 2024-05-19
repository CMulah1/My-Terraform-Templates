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

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "mulah3-bucket"
}

variable "cdn_origin_id" {
  description = "The origin ID for the CloudFront distribution"
  default     = "S3Origin"
}

variable "cloudfront_price_class" {
  description = "The price class for the CloudFront distribution"
  default     = "PriceClass_100"
}

###########-------------------------------------------------------------------------#######################
# Step3: Define AWS Resources (main.tf)

provider "aws" {
  region = var.region
}

# Create S3 Bucket
resource "aws_s3_bucket" "static_content" {
  bucket = var.bucket_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = var.bucket_name
  }
}

# Set up Bucket Policy to allow public read access
resource "aws_s3_bucket_policy" "static_content_policy" {
  bucket = aws_s3_bucket.static_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_content.arn}/*"
      }
    ]
  })
}

# Create CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Access Identity for S3 bucket"
}

# Create CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_content.bucket_regional_domain_name
    origin_id   = var.cdn_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.cdn_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "cdn-distribution"
  }
}

###########-------------------------------------------------------------------------#######################
# Step4: Define Output Variables (outputs.tf)

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.static_content.bucket
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
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
# Custom Domain and SSL: If I want to use a custom domain for my CloudFront distribution, I can configure a Route 53 record set and request an SSL certificate from AWS Certificate Manager (ACM).
# Content Delivery: Upload my static content (e.g., HTML, CSS, JavaScript files) to the S3 bucket. I can use the AWS CLI or S3 console for this purpose.
# Caching and Performance: Adjust the TTL settings in the default_cache_behavior block of the CloudFront distribution to optimize caching based on my application's needs.
# This setup provides a highly available and scalable solution for serving static content using S3 and CloudFront. It ensures that my content is delivered quickly to users around the globe with the added benefits of CloudFront's caching capabilities.
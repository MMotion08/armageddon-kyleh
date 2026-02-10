variable "aws_region" {
  description = "AWS Region for the balosar lab environment."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefix for naming (used in tags and resource names)."
  type        = string
  default     = "balosar"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.25.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.25.1.0/24", "10.25.2.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.25.101.0/24", "10.25.102.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-03ea746da1a2e36e7" # TODO
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}


variable "key_name" {
  description = "Optional EC2 key pair name. Leave null/empty to avoid SSH keys (SSM recommended)."
  type        = string
  default     = null
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet outbound internet access."
  type        = bool
  default     = false
}

variable "enable_kms_endpoint" {
  description = "Whether to create an Interface VPC Endpoint for KMS."
  type        = bool
  default     = false
}

variable "ssm_parameter_path" {
  description = "Root path for SSM parameters used by the app."
  type        = string
  default     = "/lab/db"
}
variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}


variable "storage_type" {
  description = "RDS storage type (gp3 recommended)."
  type        = string
  default     = "gp3"
}


variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "Spac3_King!" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "khughes0zx@gmail.com" # TODO: student supplies
}




############################################
# Lab 1C Bonus-A variables
############################################




variable "domain_name" {
  description = "Base domain students registered (e.g., chewbacca-growl.com)."
  type        = string
  default     = "hughes-foundation.org"
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app.chewbacca-growl.com)."
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "EMAIL"  #changed during 1c_bonus-C
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}







############################################
# Lab 1C Bonus-B variables
############################################


variable "app_port" {
  description = "Port the app listens on behind the ALB."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/"
}

variable "acm_validation_method" {
  description = "ACM validation method. Use DNS if you can manage Route53 in Terraform."
  type        = string
  default     = "DNS"
}


#added during 1c_bonus-C
variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID for the domain. Leave empty if DNS is external."
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Create a Route53 public hosted zone for domain_name."
  type        = bool
  default     = true
}


#added during 1c_bonus-C
variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  default     = ""
}


variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}
variable "acm_certificate_arn" {
  description = "ACM certificate ARN to use for the ALB. Leave blank to use the managed ACM certificate."
  type        = string
  default     = "arn:aws:acm:us-east-2:912083617270:certificate/ae5d970d-f5a4-4196-986c-671433485307"
}


# variable "acm_certificate_arn" {
#   description = "ACM certificate ARN to use for the ALB. Leave blank to use the managed ACM certificate."
#   type        = string
#   default     = "arn:aws:acm:us-east-2:912083617270:certificate/ae5d970d-f5a4-4196-986c-671433485307"
# }
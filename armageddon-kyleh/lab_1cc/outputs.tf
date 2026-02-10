# ############################################
# # Bonus-A outputs (append to outputs.tf)
# ############################################

# # Proves private SSM connectivity (no public internet)
output "balosar_vpce_ssm_id" {
  value = aws_vpc_endpoint.balosar_vpce_ssm05.id
}


# # Proves private CloudWatch Logs connectivity
output "balosar_vpce_logs_id" {
  value = aws_vpc_endpoint.balosar_vpce_logs05.id
}


# # Proves private Secrets Manager connectivity
output "balosar_vpce_secretsmanager_id" {
  value = aws_vpc_endpoint.balosar_vpce_secrets05.id
}


# # Proves S3 access without NAT or IGW (gateway endpoint)
output "balosar_vpce_s3_id" {
  value = aws_vpc_endpoint.balosar_vpce_s3_gw05.id
}

# output "balosar_private_ec2_instance_id_bonus" {
#   value = aws_instance.balosar_ec201_private_bonus.id
# }



#Explanation: Outputs are the nav computer readout—balosar needs coordinates that humans can paste into browsers.

output "balosar_route53_zone_id" { 
  value = local.balosar_zone_id 
  }

output "balosar_app_url_https" { 
  value = "https://${var.app_subdomain}.${var.domain_name}" 
  }







################################################
#output code not used but leaving here for reference:
###################################################




# ############################################
# # Bonus-B outputs (append to outputs.tf)
# ############################################


# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
# output "chewbacca_alb_dns_name" {
#   value = aws_lb.chewbacca_alb01.dns_name
# }

# output "chewbacca_app_fqdn" {
#   value = "${var.app_subdomain}.${var.domain_name}"
# }

# output "chewbacca_target_group_arn" {
#   value = aws_lb_target_group.chewbacca_tg01.arn
# }

# output "chewbacca_acm_cert_arn" {
#   value = aws_acm_certificate.chewbacca_acm_cert01.arn
# }

# output "chewbacca_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.chewbacca_waf01[0].arn : null
# }

# output "chewbacca_dashboard_name" {
#   value = aws_cloudwatch_dashboard.chewbacca_dashboard01.dashboard_name
# }




# output "balosar_private_ec2_instance_id_bonus" {
#   value = aws_instance.balosar_ec201_private_bonus.id
# }












# ############################################
# # Explanation: Log bucket name is where the footprints live—useful when hunting 5xx or WAF blocks.
# output "balosar_alb_logs_bucket_name" {
#   value = var.enable_alb_access_logs ? aws_s3_bucket.balosar_alb_logs_bucket01[0].bucket : null
# }


# # Explanation: Outputs are your mission report—what got built and where to find it.
# output "balosar_vpc_id" {
#   value = aws_vpc.balosar_vpc01.id
# }

# output "balosar_public_subnet_ids" {
#   value = aws_subnet.balosar_public_subnets[*].id
# }

# output "balosar_private_subnet_ids" {
#   value = aws_subnet.balosar_private_subnets[*].id
# }

#output "balosar_ec2_public_instance_id" {
 #   value = aws_instance.balosar_ec2_public01.id
#}

#output "balosar_ec2_private_instance_id" {
 # value = aws_instance.balosar_ec2_private01.id
#}

# output "balosar_rds_endpoint" {
#   value = aws_db_instance.balosar_rds01.address
# }

# output "balosar_sns_topic_arn" {
#   value = aws_sns_topic.balosar_sns_topic01.arn
# }

# output "balosar_log_group_name" {
#   value = "/aws/ec2/${var.project_name}-rds-app"  # Log group managed outside of Terraform
# }

# Explanation: Outputs are the nav computer readout—balosar needs coordinates that humans can paste into browsers.
# output "balosar_route53_zone_id" {
#   value = local.route53_zone_id
# }

# output "balosar_app_url_https" {
#   value = "https://${var.app_subdomain}.${var.domain_name}"
# }



# ############################################
# # Bonus-E: WAF Logging (CloudWatch, S3, Firehose)
# ############################################

# # Explicit output for CloudWatch WAF log group (Bonus-E)
# output "balosar_waf_cloudwatch_log_group" {
#   value = aws_cloudwatch_log_group.balosar_waf_log_group01[0].name
#   description = "CloudWatch log group for WAF logs (if CloudWatch is used)"
# }
# # Explanation: Coordinates for the WAF log destination—balosar wants to know where the footprints landed.
# output "balosar_waf_log_destination" {
#   value = var.waf_log_destination
# }

# output "balosar_waf_cw_log_group_name" {
#   value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.balosar_waf_log_group01[0].name : null
# }

# output "balosar_waf_logs_s3_bucket" {
#   value = var.waf_log_destination == "s3" ? aws_s3_bucket.balosar_waf_logs_bucket01[0].bucket : null
# }

# output "balosar_waf_firehose_name" {
#   value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.balosar_waf_firehose01[0].name : null
# }
# # Explanation: The apex URL is the front gate—humans type this when they forget subdomains.
# output "balosar_apex_url_https" {
#   value = "https://${var.domain_name}"
# }
output "alb_dns_name" {
  description = "ALB DNS name (use for CNAME/ALIAS if managing DNS outside Route53)."
  value       = aws_lb.balosar_alb05.dns_name
}



# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
output "balosar_alb_dns_name" {
  value = aws_lb.balosar_alb05.dns_name
}

output "balosar_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "balosar_target_group_arn" {
  value = aws_lb_target_group.balosar_alb_tg05.arn
}

output "balosar_acm_cert_arn" {
  value = data.aws_acm_certificate.balosar_existing_cert.arn
}

output "balosar_waf_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.balosar_waf05[0].arn : null
}

output "balosar_dashboard_name" {
  value = aws_cloudwatch_dashboard.balosar_alb_dashboard05.dashboard_name
}











#######################################################################################
#Output code not usable for bonus-B, but leaving here for reference:

# output "alb_arn" {
#   description = "ALB ARN."
#   value       = aws_lb.balosar_alb05.arn
# }

# output "alb_target_group_arn" {
#   description = "ALB target group ARN."
#   value       = aws_lb_target_group.balosar_alb_tg05.arn
# }

# output "acm_certificate_arn" {
#   description = "ACM certificate ARN for the app domain."
#   value       = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.balosar_acm_cert05.arn
# }

# output "acm_dns_validation_records" {
#   description = "DNS validation records to add in external DNS (name/type/value)."
#   value = [
#     for dvo in aws_acm_certificate.balosar_acm_cert05.domain_validation_options : {
#       name  = dvo.resource_record_name
#       type  = dvo.resource_record_type
#       value = dvo.resource_record_value
#     }
#   ]
# }

# output "waf_web_acl_arn" {
#   description = "WAFv2 web ACL ARN."
#   value       = aws_wafv2_web_acl.balosar_waf05.arn
# }

# output "alb_dashboard_name" {
#   description = "CloudWatch dashboard name."
#   value       = aws_cloudwatch_dashboard.balosar_alb_dashboard05.dashboard_name
# }

# output "app_url" {
#   description = "App URL (requires DNS to point to the ALB)."
#   value       = "https://${var.app_subdomain}.${var.domain_name}"
# }

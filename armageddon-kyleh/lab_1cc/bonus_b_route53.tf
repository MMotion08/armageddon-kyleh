############################################
# Bonus B - Route53 (Hosted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

locals {
  # Explanation: Balosar needs a home planet—Route53 hosted zone is your DNS territory.
  balosar_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (students choose their destiny).
  balosar_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.balosar_zone05[0].zone_id : var.route53_hosted_zone_id

  # Explanation: This is the app address that will growl at the galaxy (app.balosar-growl.com).
  balosar_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}



############################################
# Hosted Zone (optional creation)
############################################

# Explanation: A hosted zone is like claiming Kashyyyk in DNS—names here become law across the galaxy.
resource "aws_route53_zone" "balosar_zone05" {
  count = var.manage_route53_in_terraform ? 1 : 0

  name = local.balosar_zone_name

  tags = {
    Name = "${var.project_name}-zone05"
  }
}


############################################
# ACM DNS Validation Records
############################################

#Explanation: ACM asks “prove you own this planet”—DNS validation is balosar roaring in the right place.
resource "aws_route53_record" "balosar_acm_validation_records05" {
  for_each = var.certificate_validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.balosar_acm_cert05.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = local.balosar_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}



# Explanation: This ties the “proof record” back to ACM—balosar gets his green checkmark for TLS.
resource "aws_acm_certificate_validation" "balosar_acm_validation05_dns_bonus" {
  count = var.certificate_validation_method == "DNS" ? 1 : 0

  certificate_arn = data.aws_acm_certificate.balosar_existing_cert.arn

  # validation_record_fqdns = [
  #   for r in aws_route53_record.balosar_acm_validation_records05 : r.fqdn
  # ]
}






data "aws_lb" "balosar_alb" {
  name = "balosar-alb05"  # replace with your ALB name
}

resource "aws_route53_record" "balosar_app_alias" {
  zone_id = aws_route53_zone.balosar_zone05[0].zone_id
  name    = "app.hughes-foundation.org"
  type    = "A"

  alias {
    name                   = data.aws_lb.balosar_alb.dns_name
    zone_id                = data.aws_lb.balosar_alb.zone_id
    evaluate_target_health = true
  }
}








############################################
#ALIAS record: app.hughes-foundation.org -> ALB
############################################



#Explanation: This is the holographic sign outside the cantina—app.hughes-foundation.org points to your ALB.

resource "aws_route53_record" "balosar_app_alias05" {
  zone_id = local.balosar_zone_id
  name    = local.balosar_app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.balosar_alb05.dns_name
    zone_id               = aws_lb.balosar_alb05.zone_id
    evaluate_target_health = true
  }
}






#######################################################################################
# code not usable for bonus-B, but leaving here for reference:
#####################################################################################



# # Rrrrrrr... Hosted Zone (optional, if Terraform manages Route53)
# resource "aws_route53_zone" "balosar_zone05" {
#   count = var.manage_route53_in_terraform ? 1 : 0
#   name  = var.domain_name

#   tags = {
#     Name = "${local.name_prefix}-hosted-zone"
#   }
# }





# # Wrrrgh... DNS validation records for ACM (only when DNS validation is used)
# resource "aws_route53_record" "balosar_acm_validation" {
#   for_each = var.manage_route53_in_terraform && var.acm_validation_method == "DNS" ? {
#     for dvo in aws_acm_certificate.balosar_acm_cert01.domain_validation_options :
#     dvo.domain_name => {
#       name  = dvo.resource_record_name
#       type  = dvo.resource_record_type
#       value = dvo.resource_record_value
#     }
#   } : {}

#   zone_id = local.route53_zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.value]
#   ttl     = 60
# }




# Raaaaargh... Validate ACM certificate via DNS
# resource "aws_acm_certificate_validation" "balosar_acm_cert_validation" {
#   count           = var.manage_route53_in_terraform && var.acm_validation_method == "DNS" ? 1 : 0
#   certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.balosar_acm_cert01.arn
#   validation_record_fqdns = [
#     for record in aws_route53_record.balosar_acm_validation : record.fqdn
#   ]
# }

# app.hughes-foundation.org ALIAS -> ALB


# resource "aws_route53_record" "balosar_app_alias" {
#   count   = var.manage_route53_in_terraform ? 1 : 0
#   zone_id = local.route53_zone_id
#   name    = local.balosar_fqdn
#   type    = "A"

#   alias {
#     name                   = aws_lb.balosar_alb05.dns_name
#     zone_id                = aws_lb.balosar_alb05.zone_id
#     evaluate_target_health = true
#   }
# }

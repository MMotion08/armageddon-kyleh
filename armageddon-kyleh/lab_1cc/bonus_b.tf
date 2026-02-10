############################################
# Lab 1C Bonus-B: ALB + TLS + WAF + Monitoring
############################################

locals {
  # Explanation: This is the roar address — where the galaxy finds your app.
  balosar_fqdn = "${var.app_subdomain}.${var.domain_name}"
  route53_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.balosar_zone05[0].zone_id : var.route53_hosted_zone_id
}

############################################
# ALB Security Group
############################################


# Explanation: The ALB SG is the blast shield — only allow what the Rebellion needs (80/443).
resource "aws_security_group" "balosar_alb_sg05" {
  name        = "${local.name_prefix}-alb-sg05"
  description = "ALB security group"
  vpc_id      = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-alb-sg05"
  }
}

resource "aws_vpc_security_group_ingress_rule" "balosar_alb_sg_ingress_http" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.balosar_alb_sg05.id
  from_port         = local.ports_http
  to_port           = local.ports_http
  cidr_ipv4         = local.all_ip_address
}

resource "aws_vpc_security_group_ingress_rule" "balosar_alb_sg_ingress_https" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.balosar_alb_sg05.id
  from_port         = local.ports_https
  to_port           = local.ports_https
  cidr_ipv4         = local.all_ip_address
}

resource "aws_vpc_security_group_egress_rule" "balosar_alb_sg_egress_app" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.balosar_alb_sg05.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.balosar_ec2_sg05.id
}

#Explanation: The ALB is your public customs checkpoint — it speaks TLS and forwards to private targets.
resource "aws_lb" "balosar_alb05" {
  name               = "${var.project_name}-alb05"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.balosar_alb_sg05.id]
  subnets         = aws_subnet.balosar_public_subnets[*].id





  tags = {
    Name = "${var.project_name}-alb05"
  }
}







resource "aws_lb_target_group" "balosar_alb_tg05" {
  name     = "${local.name_prefix}-tg05"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.balosar_vpc05.id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${local.name_prefix}-tg05"
  }
}

resource "aws_lb_target_group_attachment" "balosar_alb_tg_attach05" {
  target_group_arn = aws_lb_target_group.balosar_alb_tg05.arn
  target_id        = aws_instance.balosar_ec205.id
  port             = var.app_port
}

resource "aws_lb_listener" "balosar_alb_http" {
  load_balancer_arn = aws_lb.balosar_alb05.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

############################################
# ACM Certificate (TLS) for app.hughes-foundation.org
############################################

resource "aws_acm_certificate" "balosar_acm_cert05" {
  domain_name       = local.balosar_fqdn
  validation_method = var.acm_validation_method

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_acm_certificate" "balosar_existing_cert" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  types      = ["AMAZON_ISSUED"]
  most_recent = true
}


####Commented out for 1c bonus-C since we're using an existing cert####
# resource"aws_acm_certificate_validation" "balosar_acm_cert_validation" {
#   certificate_arn = data.aws_acm_certificate.balosar_existing_cert.arn

# }


#   # Explanation: If using DNS validation and Terraform manages Route53, it will create the necessary records.
#   validation_record_fqdns = var.manage_route53_in_terraform && var.acm_validation_method == "DNS" ? [
#     for record in aws_route53_record.balosar_acm_validation : record.fqdn
#   ] : []
# }


resource "aws_lb_listener" "balosar_alb_https" {
  load_balancer_arn = aws_lb.balosar_alb05.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.balosar_existing_cert.arn #listener already using existing cert arn from data source

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.balosar_alb_tg05.arn
  }

  #depends_on = [aws_acm_certificate_validation.balosar_acm_cert_validation]

}




#Explanation: HTTPS listener is the real hangar bay — TLS terminates here, then traffic goes to private targets.

resource "aws_lb_listener" "balosar_https" {
  load_balancer_arn = aws_lb.balosar_alb05.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.balosar_existing_cert.arn  # <-- ACM cert ARN, not listener ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.balosar_alb_tg05.arn
  }

  # optional: ensure certificate validation completes first
  # depends_on = [
  #   aws_acm_certificate_validation.balosar_acm_cert_validation
  # ]
}

  # Ensure the ACM certificate is fully validated before creating listener


############################################
# WAFv2 Web ACL (Basic managed rules)
############################################


# Explanation: WAF is the shield generator — it blocks the cheap blaster fire before it hits your ALB.
resource "aws_wafv2_web_acl" "balosar_waf05" {
  count = var.enable_waf ? 1 : 0
  
  name  = "${local.name_prefix}-waf05"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

 visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common"
      sampled_requests_enabled   = true
    }

# Explanation: AWS managed rules are like hiring Rebel commandos — they’ve seen every trick.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common"
      sampled_requests_enabled   = true
    }
  }


  tags = {
    Name = "${local.name_prefix}-waf05"
  }
}
###Uncomment later###
# # Explanation: Attach the shield generator to the customs checkpoint — ALB is now protected.
# resource "aws_wafv2_web_acl_association" "balosar_waf_assoc05" {
#   count = var.enable_waf ? 1 : 0
  

#   resource_arn = aws_lb.balosar_alb05.arn
#   web_acl_arn  = aws_wafv2_web_acl.balosar_waf05.arn
# }

############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################


# Explanation: When the ALB starts throwing 5xx, that’s the Falcon coughing — page the on-call Wookiee.
resource "aws_cloudwatch_metric_alarm" "balosar_alb_5xx_alarm05" {
  alarm_name          = "${local.name_prefix}-alb-5xx-alarm05"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"


  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  

  dimensions = {
    LoadBalancer = aws_lb.balosar_alb05.arn_suffix
  }

  alarm_actions = [aws_sns_topic.balosar_sns_topic05.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-alb-5xx-alarm05"
  }
}



############################################
# CloudWatch Dashboard (Skeleton)
############################################


resource "aws_cloudwatch_dashboard" "balosar_alb_dashboard05" {
  dashboard_name = "${local.name_prefix}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB 5XX"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.balosar_alb05.arn_suffix]
          ]
          stat   = "Sum"
          period = 300
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.balosar_alb05.arn_suffix, "TargetGroup", aws_lb_target_group.balosar_alb_tg05.arn_suffix]
          ]
          stat   = "Average"
          period = 300
          region = var.aws_region
          title  = "Balosar ALB: Target Response Time"
          
        }
      }
    ]
  })
}



############################################################
#code not usable for bonus-B, but leaving here for reference:
#############################################################


############################################
# ALB + Target Group + Listeners
############################################

# resource "aws_lb" "balosar_alb05" {
#   name               = "${local.name_prefix}-alb05"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.balosar_alb_sg05.id]
#   subnets            = aws_subnet.balosar_public_subnets[*].id

#   tags = {
#     Name = "${local.name_prefix}-alb05"
#   }
#   # Explanation: balosar keeps flight logs—ALB access logs go to S3 for audits and incident response.
#   access_logs {
#     bucket  = aws_s3_bucket.balosar_alb_logs_bucket05[0].bucket
#     prefix  = var.alb_access_logs_prefix
#     enabled = var.enable_alb_access_logs
#   }
# }



###Uncomment at Bonus D###

  # Explanation: balosar keeps flight logs—ALB access logs go to S3 for audits and incident response.
  # access_logs {
  #   bucket  = aws_s3_bucket.balosar_alb_logs_bucket05[0].bucket
  #   prefix  = var.alb_access_logs_prefix
  #   enabled = var.enable_alb_access_logs
  # }

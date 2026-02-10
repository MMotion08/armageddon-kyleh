############################################
# Locals (naming convention: balosar-*)
############################################
locals {
  name_prefix = var.project_name
  ports_http  = 80
  ports_ssh   = 22
  ports_https = 443
  # ports_dns = 53
  db_port        = 3306
  tcp_protocol   = "tcp"
  udp_protocol   = "udp"
  all_ip_address = "0.0.0.0/0"
  # For AWS SG rules, "all protocols" is represented by ip_protocol = "-1".
  # When ip_protocol = "-1", AWS expects from_port/to_port to be 0.
  all_ports    = 0
  all_protocol = "-1"
}

data "aws_caller_identity" "current" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

############################################
# VPC + Internet Gateway
############################################

# Explanation: balosar needs a hyperlane for this VPC is the Millennium Falcon's flight corridor.
resource "aws_vpc" "balosar_vpc05" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc05"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy's IGW is your door to the public internet.
resource "aws_internet_gateway" "balosar_igw05" {
  vpc_id = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-igw05"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays ships can land directly from space (internet).
resource "aws_subnet" "balosar_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.balosar_vpc05.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are the hidden Rebel base's "no direct access from the internet."
resource "aws_subnet" "balosar_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.balosar_vpc05.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  
  

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# Explanation: balosar wants the private base to call home's EIP gives the NAT a stable "holonet address."
resource "aws_eip" "_nat_eip05" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip05"
  }
}

# Explanation: NAT is balosar's smuggler tunnel's ”private subnets can reach out without being seen.
resource "aws_nat_gateway" "balosar_nat05" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip._nat_eip05[0].id
  subnet_id     = aws_subnet.balosar_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat05"
  }

  depends_on = [aws_internet_gateway.balosar_igw05]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = open lanes to the galaxy via IGW.
resource "aws_route_table" "_public_rt05" {
  vpc_id = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-public-rt05"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "balosar_public_default_route" {
  route_table_id         = aws_route_table._public_rt05.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.balosar_igw05.id
}

# Explanation: Attach public subnets to the "public lanes."
resource "aws_route_table_association" "balosar_public_rta" {
  count          = length(aws_subnet.balosar_public_subnets)
  subnet_id      = aws_subnet.balosar_public_subnets[count.index].id
  route_table_id = aws_route_table._public_rt05.id
}

# Explanation: Private route table = "stay hidden, but still ship supplies."
resource "aws_route_table" "_private_rt05" {
  vpc_id = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-private-rt05"
  }
}

# Explanation: Private subnets route outbound internet via NAT (balosar-approved stealth).
resource "aws_route" "balosar_private_default_route" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table._private_rt05.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.balosar_nat05[0].id
}

# Explanation: Attach private subnets to the "stealth lanes."
resource "aws_route_table_association" "balosar_private_rta" {
  count          = length(aws_subnet.balosar_private_subnets)
  subnet_id      = aws_subnet.balosar_private_subnets[count.index].id
  route_table_id = aws_route_table._private_rt05.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is balosar's bodyguard—only let in what you mean to.
resource "aws_security_group" "balosar_ec2_sg05" {
  name        = "${local.name_prefix}-ec2-sg05"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg05"
  }
}
# resource "aws_security_group" "balosar_ec2_sg02" {
#   name        = "${local.name_prefix}-ec2-sg02"
#   description = "EC2 app security group"
#   vpc_id      = aws_vpc.balosar_vpc05.id

#   tags = {
#     Name = "${local.name_prefix}-ec2-sg02"
#   }
# }

# Explanation: VPC endpoint SG allows private instances to reach AWS APIs via Interface Endpoints.
resource "aws_security_group" "balosar_vpce_sg05" {
  name        = "${local.name_prefix}-vpce-sg05"
  description = "Interface VPC endpoints security group"
  vpc_id      = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-vpce-sg05"
  }
}

resource "aws_vpc_security_group_ingress_rule" "balosar_vpce_sg_ingress_https" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.balosar_vpce_sg05.id
  from_port                    = local.ports_https
  to_port                      = local.ports_https
  referenced_security_group_id = aws_security_group.balosar_ec2_sg05.id
}

resource "aws_vpc_security_group_egress_rule" "balosar_vpce_sg_egress_all" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.balosar_vpce_sg05.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
}

# Adds inbound rules (HTTP 80, SSH 22 from their IP)

resource "aws_vpc_security_group_ingress_rule" "balosar_ec2_sg_ingress_http" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.balosar_ec2_sg05.id
  from_port         = local.ports_http
  to_port           = local.ports_http
  cidr_ipv4         = var.vpc_cidr
}



# Tightened egress: DB + AWS endpoints + S3 + DNS
resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_db" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.balosar_ec2_sg05.id
  from_port                    = local.db_port
  to_port                      = local.db_port
  referenced_security_group_id = aws_security_group.balosar_rds_sg05.id
}

resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_https_vpce" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.balosar_ec2_sg05.id
  from_port                    = local.ports_https
  to_port                      = local.ports_https
  referenced_security_group_id = aws_security_group.balosar_vpce_sg05.id
}

resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_https_s3" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.balosar_ec2_sg05.id
  from_port         = local.ports_https
  to_port           = local.ports_https
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_dns_udp" {
  ip_protocol       = local.udp_protocol
  security_group_id = aws_security_group.balosar_ec2_sg05.id
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_dns_tcp" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.balosar_ec2_sg05.id
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.vpc_cidr
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "balosar_rds_sg05" {
  name        = "${local.name_prefix}-rds-sg05"
  description = "RDS security group"
  vpc_id      = aws_vpc.balosar_vpc05.id

  tags = {
    Name = "${local.name_prefix}-rds-sg05"
  }
}

# TODO: student adds inbound MySQL 3306 from aws_security_group.balosar_ec2_sg05.id

resource "aws_vpc_security_group_ingress_rule" "balosar_rds_sg_ingress_mysql" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.balosar_rds_sg05.id
  from_port                    = local.db_port
  to_port                      = local.db_port
  referenced_security_group_id = aws_security_group.balosar_ec2_sg05.id #allow traffic ONLY from specified SG
}


############################################
# RDS Subnet Group
############################################

# Explanation: RDS hides in private subnets like the Rebel base on Hothâ€”cold, quiet, and not public.
resource "aws_db_subnet_group" "balosar_rds_subnet_group05" {
  name       = "${local.name_prefix}-rds-subnet-group05"
  subnet_ids = aws_subnet.balosar_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group05"
  }
}

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the holocron of stateâ€”your relational data lives here, not on the EC2.
resource "aws_db_instance" "balosar_rds05" {
  identifier               = "${local.name_prefix}-rds05"
  engine                   = var.db_engine
  instance_class           = var.db_instance_class
  storage_type             = var.storage_type
  allocated_storage        = 20
  backup_retention_period  = 0  # Free tier: set to 0 to disable automated backups
  db_name                  = var.db_name
  username                 = var.db_username
  password                 = var.db_password
  multi_az                 = false  # Free tier limitation: set to false
  delete_automated_backups = false

  db_subnet_group_name   = aws_db_subnet_group.balosar_rds_subnet_group05.name
  vpc_security_group_ids = [aws_security_group.balosar_rds_sg05.id]

  publicly_accessible = false
  skip_final_snapshot = true

  # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = {
    Name = "${local.name_prefix}-rds05"
  }

  depends_on = [aws_db_subnet_group.balosar_rds_subnet_group05, aws_security_group.balosar_rds_sg05]
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: Chewbacca refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "balosar_ec2_role05" {
  name = "${local.name_prefix}-ec2-role05"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle {
    ignore_changes = all
  }
}
# resource "aws_iam_role" "balosar_ec2_role02" {
#   name = "${local.name_prefix}-ec2-role02"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# Explanation: These policies are your Wookiee toolbelt to tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "balosar_ec2_ssm_attach" {
  role       = aws_iam_role.balosar_ec2_role05.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# resource "aws_iam_role_policy_attachment" "balosar_ec2_ssm_attach02" {
#   role       = aws_iam_role.balosar_ec2_role02.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# Explanation: EC2 must read secrets/params during recovery to give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "balosar_ec2_secrets_attach" {
  role       = aws_iam_role.balosar_ec2_role05.name
  policy_arn = "arn:aws:iam::912083617270:policy/secrets_policy"
}

# Explanation: CloudWatch logs are the starship's black box. You need them when things explode.
resource "aws_iam_role_policy_attachment" "balosar_ec2_cw_attach" {
  role       = aws_iam_role.balosar_ec2_role05.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "balosar_instance_profile05" {
  name = "${local.name_prefix}-instance-profile05"
  role = aws_iam_role.balosar_ec2_role05.name

  lifecycle {
    ignore_changes = all
  }
}


############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your Han Solo box. It talks to RDS and complains loudly when the DB is down.


resource "aws_instance" "balosar_ec205" {
  ami                         = "ami-03ea746da1a2e36e7"  # Amazon Linux 2023 in us-east-2
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.balosar_private_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.balosar_ec2_sg05.id]
  iam_instance_profile        = aws_iam_instance_profile.balosar_instance_profile05.name
  user_data_replace_on_change = true
  associate_public_ip_address = false
  
  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  user_data  = file("${path.module}/1a_user_data.sh")
  depends_on = [aws_db_instance.balosar_rds05]

  tags = {
    Name = "${local.name_prefix}-ec205"
  }
}





############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is balosar’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "balosar_db_endpoint_param" {
  name      = "/lab/db/endpoint"
  type      = "String"
  value     = aws_db_instance.balosar_rds05.address
  overwrite = true  # Allow overwrite if parameter already exists

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "balosar_db_port_param" {
  name      = "/lab/db/port"
  type      = "String"
  value     = tostring(aws_db_instance.balosar_rds05.port)
  overwrite = true  # Allow overwrite if parameter already exists

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "balosar_db_name_param" {
  name      = "/lab/db/name"
  type      = "String"
  value     = var.db_name
  overwrite = true  # Allow overwrite if parameter already exists

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is balosar's locked holster credentials go here, not in code.
#Recovery_window_in_days forces deletion of secrets and allows re-deployment of secret without constantly changing name

resource "aws_secretsmanager_secret" "balosar_db_secret05" {
  name                    = "lab1c/rds/mysql05"
  recovery_window_in_days = 0
}

# Explanation: Secret payloadâ€”students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "balosar_db_secret_version05" {
  secret_id = aws_secretsmanager_secret.balosar_db_secret05.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.balosar_rds05.address
    port     = aws_db_instance.balosar_rds05.port
    dbname   = var.db_name
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparkedâ€”ship them centrally.
# NOTE: CloudWatch log group already exists in AWS, managed outside of Terraform for now
resource "aws_cloudwatch_log_group" "balosar_log_group05" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group05"
  }

  lifecycle {
    ignore_changes = all
  }

  depends_on = [aws_vpc.balosar_vpc05]
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# Explanation: Metrics are balosar' growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "balosar_db_alarm05" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.balosar_sns_topic05.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "balosar_sns_topic05" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "balosar_sns_sub05" {
  topic_arn = aws_sns_topic.balosar_sns_topic05.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

############################################
# (Optional but realistic) VPC Endpoints (Skeleton)
############################################

resource "aws_vpc_endpoint" "balosar_vpce_ssm05" {
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_ec2messages" {
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_ssmmessages" {
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_logs05" {
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_secrets05" {
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-secretsmanager"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_kms" {
  count               = var.enable_kms_endpoint ? 1 : 0
  vpc_id              = aws_vpc.balosar_vpc05.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.balosar_private_subnets[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.balosar_vpce_sg05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-kms"
  }
}

resource "aws_vpc_endpoint" "balosar_vpce_s3_gw05" {
  vpc_id            = aws_vpc.balosar_vpc05.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table._private_rt05.id]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}




#################################################
#Code left here for future use
#################################################



# resource "aws_vpc_security_group_ingress_rule" "balosar_bastion_host_sg_ingress_ssh" {
#   ip_protocol       = local.tcp_protocol
#   security_group_id = aws_security_group.balosar_ec2_sg02.id
#   from_port         = local.ports_ssh
#   to_port           = local.ports_ssh
#   cidr_ipv4         = var.my_ip_cidr
# }
# resource "aws_vpc_security_group_ingress_rule" "balosar_ec2_sg_ingress_private_ssh" {
#   ip_protocol                  = local.tcp_protocol
#   security_group_id            = aws_security_group.balosar_ec2_sg02.id
#   from_port                    = local.ports_ssh
#   to_port                      = local.ports_ssh
#   referenced_security_group_id = aws_security_group.balosar_ec2_sg02.id #allow traffic ONLY from specified SG
# }


# Ensures outbound allows DB port to RDS SG (or allow all outbound)
# Chris- We should not need http, but keeping it
# resource "aws_vpc_security_group_egress_rule" "balosar_ec2_sg_egress_http" {
#   ip_protocol       = local.tcp_protocol
#   security_group_id = aws_security_group.balosar_ec2_sg05.id
#   from_port         = local.ports_http
#   to_port           = local.ports_http
#   cidr_ipv4         = local.all_ip_address
# }



# resource "aws_iam_instance_profile" "balosar_instance_profile02" {
#   name = "${local.name_prefix}-instance-profile02"
#   role = aws_iam_role.balosar_ec2_role02.name
# }
# resource "aws_iam_policy" "balosar_secrets_policy" {
#   name        = "secrets_policy"
#   description = "EC2 to RDS using Secrets Manager"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "ReadSpecificSecret",
#         "Effect" : "Allow",
#         "Action" : [
#           "secretsmanager:GetSecretValue"
#         ],
#         "Resource" : "${aws_secretsmanager_secret.balosar_db_secret01.arn}*"
#       }
#     ]
#   })

#   lifecycle {
#     ignore_changes = all
#   }
# }

# resource "aws_iam_policy" "balosar_ssm_param_policy" {
#   name        = "ssm_param_read_policy"
#   description = "EC2 read-only access to app SSM parameters"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "ReadAppParams",
#         "Effect" : "Allow",
#         "Action" : [
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ],
#         "Resource" : "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_path}/*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "balosar_ec2_ssm_param_attach" {
#   role       = aws_iam_role.balosar_ec2_role05.name
#   policy_arn = aws_iam_policy.balosar_ssm_param_policy.arn
# }








###uncomment in Bonus-B###
# resource "aws_instance" "balosar_bastion_host_ec2_205" {
#   ami                         = "ami-06e3c045d79fd65d9"  # Ubuntu 22.04 LTS in us-east-2
#   instance_type               = var.ec2_instance_type
#   subnet_id                   = aws_subnet.balosar_private_subnets[0].id
#   vpc_security_group_ids      = [aws_security_group.balosar_ec2_sg05.id]
#   iam_instance_profile        = aws_iam_instance_profile.balosar_instance_profile05.name
#   # user_data_replace_on_change = true
#   associate_public_ip_address = false
  
#   # TODO: student supplies user_data to install app + CW agent + configure log shipping
#   user_data  = file("${path.module}/1a_user_data.sh")
#   # depends_on = [aws_db_instance.balosar_rds05]

#   tags = {
#     Name = "${local.name_prefix}-bastion-host-ec2-205"
#   }
# }


### Uncomment in Bonus B###
# resource "aws_instance" "balosar_ec2_03" {
#   ami                         = "ami-0030e4319cbf4dbf2"  # Ubuntu 22.04 LTS in us-east-2
#   instance_type               = var.ec2_instance_type
#   subnet_id                   = aws_subnet.balosar_private_subnets[1].id
#   vpc_security_group_ids      = [aws_security_group.balosar_ec2_sg05.id]
#   iam_instance_profile        = aws_iam_instance_profile.balosar_instance_profile05.name
#   #user_data_replace_on_change = true
#   associate_public_ip_address = false
#   # key_name = var.key_name
#   # TODO: student supplies user_data to install app + CW agent + configure log shipping
#   #user_data  = file("${path.module}/1a_user_data.sh")
#   # depends_on = [aws_db_instance.balosar_rds05]

#   tags = {
#     Name = "${local.name_prefix}-ec2_03"
#   }
# }

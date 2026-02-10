# Explanation: Outputs are your mission report—what got built and where to find it.
output "balosar_vpc_id" {
  value = aws_vpc.balosar_vpc01.id
}

output "balosar_public_subnet_ids" {
  value = aws_subnet.balosar_public_subnets[*].id
}

output "balosar_private_subnet_ids" {
  value = aws_subnet.balosar_private_subnets[*].id
}

# output "balosar_ec2_instance_id" {
#   value = aws_instance.balosar_ec201.id
# }

output "balosar_rds_endpoint" {
  value = aws_db_instance.balosar_rds01.address
}

output "balosar_sns_topic_arn" {
  value = aws_sns_topic.balosar_sns_topic01.arn
}

output "balosar_log_group_name" {
  value = aws_cloudwatch_log_group.balosar_log_group01.name
}
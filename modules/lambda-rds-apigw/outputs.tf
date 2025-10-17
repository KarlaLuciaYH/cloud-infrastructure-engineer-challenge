output "lambda_subnet_ids" {
  description = "Private subnet IDs dedicated to the Lambda function."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

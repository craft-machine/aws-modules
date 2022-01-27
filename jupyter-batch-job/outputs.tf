output "job_definition_name" {
  value = aws_batch_job_definition.main.name
}

output "job_role_name" {
  value = aws_iam_role.main.name
}

output "job_role_arn" {
  value = aws_iam_role.main.arn
}

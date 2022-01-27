output "lb_target_group_arn" {
  value = aws_lb_target_group.main.arn
}

output "ecs_task_role_name" {
  value = aws_iam_role.ecs_task.name
}

output "ecs_task_execution_role_name" {
  value = aws_iam_role.ecs_task_execution.name
}

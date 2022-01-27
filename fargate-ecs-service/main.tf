### ECS Service

resource "aws_ecs_service" "main" {
  name                  = var.container_name
  cluster               = var.ecs_cluster_id
  task_definition       = aws_ecs_task_definition.main.arn
  desired_count         = 0
  wait_for_steady_state = var.wait_for_steady_state

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets = var.subnets
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
    base              = var.max_capacity
  }
}

### ECS Task Definition

resource "aws_ecs_task_definition" "main" {
  family                   = var.container_name
  container_definitions    = var.container_definitions
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  requires_compatibilities = ["FARGATE"]
  memory                   = var.memory_limit
  cpu                      = var.cpu_limit
}

resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_group
  retention_in_days = 90
}

### ECS Task Execution Role

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.container_name}_ecs_task_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution.id
}

### ECS Task SSM Permission Role

resource "aws_iam_role" "ecs_task" {
  name = "${var.container_name}_ecs_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_ssm_access" {
  name   = "ecs_task_ssm_policy"
  policy = data.aws_iam_policy_document.ssm_access.json
  role   = aws_iam_role.ecs_task.id
}

### ECS Service SQS based autoscaling

resource "aws_cloudwatch_metric_alarm" "sqs_queue_not_empty" {
  alarm_name          = "${var.sqs_queue_name}_not_empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Processing messages count"

  metric_query {
    id          = "total_count"
    expression  = "visible+in_flight"
    label       = "Total processing messages"
    return_data = "true"
  }

  metric_query {
    id = "visible"

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      period      = "300"
      stat        = "Average"

      dimensions = {
        QueueName = var.sqs_queue_name
      }
    }
  }

  metric_query {
    id = "in_flight"

    metric {
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      namespace   = "AWS/SQS"
      period      = "300"
      stat        = "Average"

      dimensions = {
        QueueName = var.sqs_queue_name
      }
    }
  }

  alarm_actions = [aws_appautoscaling_policy.service_scale_up.arn]
  ok_actions    = [aws_appautoscaling_policy.service_scale_down.arn]
}

resource "aws_appautoscaling_target" "service" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.container_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.service_autoscaling_target.arn
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  depends_on = [aws_ecs_service.main]
}

resource "aws_appautoscaling_policy" "service_scale_up" {
  name               = "${var.container_name}_scale_up"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.max_capacity
    }
  }
}

resource "aws_appautoscaling_policy" "service_scale_down" {
  name               = "${var.container_name}_scale_down"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 0
    }
  }
}

resource "aws_iam_role" "service_autoscaling_target" {
  name = "${var.container_name}_ecs_service_autoscaling_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "service_autoscaling_target" {
  name   = "ecs_service_autoscaling_policy"
  policy = data.aws_iam_policy_document.service_autoscaling.json
  role   = aws_iam_role.service_autoscaling_target.id
}

data "aws_iam_policy_document" "service_autoscaling" {
  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]

    resources = [
      aws_ecs_service.main.id,
    ]
  }

  statement {
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:putMetricAlarm",
      "cloudwatch:putMetricData",
    ]

    resources = [
      "*",
    ]
  }
}

locals {
  capacity_provider_strategies = {
    enabled = [
      {
        capacity_provider = var.capacity_provider
        weight            = 1
      },
    ]
    disabled = []
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = var.container_name
  container_definitions = var.container_definitions
  network_mode          = "bridge"
}

resource "aws_ecs_service" "service" {
  count = var.enabled == false ? "0" : var.service_without_lb_count == 0 ? "1" : "0"

  name                  = var.container_name
  cluster               = var.ecs_cluster_id
  task_definition       = aws_ecs_task_definition.task_definition.arn
  desired_count         = var.min_capacity
  iam_role              = aws_iam_role.ecs_role.arn
  wait_for_steady_state = var.wait_for_steady_state

  depends_on = [
    aws_iam_role.ecs_role,
    aws_lb_target_group.lb_target,
    aws_ecs_task_definition.task_definition,
  ]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  dynamic "capacity_provider_strategy" {
    for_each = local.capacity_provider_strategies[length(var.capacity_provider) == 0 ? "disabled" : "enabled"]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      base              = lookup(capacity_provider_strategy.value, "base", null)
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
    }
  }
}

resource "aws_ecs_service" "service_without_lb" {
  count           = var.service_without_lb_count
  name            = var.container_name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.min_capacity
  depends_on = [
    aws_iam_role.ecs_role,
    aws_lb_target_group.lb_target,
  ]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  dynamic "capacity_provider_strategy" {
    for_each = local.capacity_provider_strategies[length(var.capacity_provider) == 0 ? "disabled" : "enabled"]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      base              = lookup(capacity_provider_strategy.value, "base", null)
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
    }
  }
}

resource "aws_lb_target_group" "lb_target" {
  name     = var.container_name
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "application-autoscaling:*",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:putMetricAlarm",
      "cloudwatch:putMetricData",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
  role   = aws_iam_role.ecs_role.id
}

resource "aws_iam_role" "ecs_role" {
  name               = "${var.container_name}_ecs_role"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_for_assume_role.json
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.log_group
  retention_in_days = 90
}

resource "aws_iam_role_policy_attachment" "ec2_service_role" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = aws_iam_role.ecs_role.name
  role = aws_iam_role.ecs_role.name
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.container_name}_ecs_instance_profile"
  path = "/"
  role = aws_iam_role.ecs_role.name
}

resource "aws_security_group" "container_instance" {
  vpc_id = var.vpc_id

  name        = "${var.container_name}_allow_vpc_ecs"
  description = "Allow vpc traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_metric_alarm" "service_high" {
  alarm_name          = "${var.container_name}_service_cpu_utilization_high_30"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.container_name
  }

  alarm_actions = [aws_appautoscaling_policy.service_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_low" {
  count               = var.cpu_low_alarm_enbaled == true ? 1 : 0
  alarm_name          = "${var.container_name}_service_cpu_utilization_low_5"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.container_name
  }

  alarm_actions = [aws_appautoscaling_policy.service_down[0].arn]
}

resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.container_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_role.arn
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "service_up" {
  name               = "${var.container_name}_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.container_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.scale_target]
}

resource "aws_appautoscaling_policy" "service_down" {
  count              = var.cpu_low_alarm_enbaled == true ? 1 : 0
  name               = "${var.container_name}_service_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.container_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.scale_target]
}

output "aws_lb_target_group_lb_target_arn" {
  value = aws_lb_target_group.lb_target.arn
}

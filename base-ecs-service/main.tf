locals {
  container_name_snake_case = replace(var.container_name, "-", "_")
}

resource "aws_ecs_service" "main" {
  name                               = var.container_name
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = var.desired_count
  iam_role                           = var.ecs_service_role_arn
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  wait_for_steady_state              = var.wait_for_steady_state

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  dynamic "capacity_provider_strategy" {
    for_each = compact([var.capacity_provider])
    content {
      capacity_provider = var.capacity_provider
      weight            = 1
    }
  }
}

resource "aws_ecs_task_definition" "main" {
  family                = var.container_name
  container_definitions = var.container_definitions
  network_mode          = "bridge" # TODO: consider using awsvpc network mode instead (will at least require target_type = "ip" setup for the target group and turning awsvpcTrunking on)
  task_role_arn         = aws_iam_role.ecs_task.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value["name"]
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", null) != null ? [volume.value["docker_volume_configuration"]] : []
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", "shared")
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }
      
      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", null) != null ? [volume.value["efs_volume_configuration"]] : []
        content {
          file_system_id          = efs_volume_configuration.value["file_system_id"]
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          
          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", null) != null ? [efs_volume_configuration.value["authorization_config"]] : []
            content {
              access_point_id = authorization_config.value["access_point_id"]
              iam             = authorization_config.value["iam"]
            }
          }
        }
      }
    }
  }
}

resource "aws_iam_role" "ecs_task" {
  name        = "${local.container_name_snake_case}_ecs_task_role"
  description = "Allow ECS tasks to access AWS resources"

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

resource "aws_iam_role" "ecs_task_execution" {
  name        = "${local.container_name_snake_case}_ecs_task_execution_role"
  description = "Role that Amazon ECS container agent and the Docker daemon can assume."

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
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb_target_group" "main" {
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

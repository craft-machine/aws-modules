locals {

  repository_name_snake_case = replace(var.repository_name, "-", "_")
  task_name_snake_case = replace(var.task_name, "-", "_")

  schedule_name_snake_case = replace(var.schedule_name, "-", "_")
  schedule_name_pascal_case = replace(
  title(replace(local.schedule_name_snake_case, "_", " ")),
  " ",
  "",
  )

  # https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html
  job_role_name_full = "${local.repository_name_snake_case}_${local.task_name_snake_case}_job_role"
  job_role_name_hash = join(
    "",
    [
      substr(local.job_role_name_full, 0, 32),
      md5(substr(local.job_role_name_full, 32, -1)),
    ],
  )
  job_role_name = length(local.job_role_name_full) <= 64 ? local.job_role_name_full : local.job_role_name_hash

  # https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html
  schedule_role_name_full = "${local.repository_name_snake_case}_${local.task_name_snake_case}_${local.schedule_name_snake_case}"
  schedule_role_name_hash = join(
    "",
    [
      substr(local.schedule_role_name_full, 0, 32),
      md5(substr(local.schedule_role_name_full, 32, -1)),
    ],
  )
  schedule_role_name = length(local.schedule_role_name_full) <= 64 ? local.schedule_role_name_full : local.schedule_role_name_hash

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-events-rule.html
  schedule_rule_name_full = "${local.repository_name_snake_case}_${local.task_name_snake_case}_job_schedule"
  schedule_rule_name_hash = join(
    "",
    [
      substr(local.schedule_rule_name_full, 0, 32),
      md5(substr(local.schedule_rule_name_full, 32, -1)),
    ],
  )
  schedule_rule_name = length(local.schedule_rule_name_full) <= 64 ? local.schedule_rule_name_full : local.schedule_rule_name_hash

  deploy_schedule = var.schedule_cron == "" ? 0 : 1
}


### Batch ###

resource "aws_batch_job_definition" "main" {
  name = "${local.repository_name_snake_case}-${local.task_name_snake_case}"
  type = "container"

  timeout {
    attempt_duration_seconds = var.job_timeout
  }

  retry_strategy {
    attempts = 1
  }

  parameters = {
    "default_parameters"  = jsonencode(var.parameters)
    "parameters"          = "{}"
  }

  container_properties = <<CONTAINER_PROPERTIES
{
  "image": "${var.docker_image}",
  "vcpus": ${var.container_vcpus},
  "memory": ${var.container_memory},
  "command": [
  ],
  "jobRoleArn": "${aws_iam_role.main.arn}",
  "volumes": ${jsonencode(var.container_volumes)},
  "mountPoints": ${jsonencode(var.container_mount_points)},
  "environment": [
    {
      "name": "AWS_DEFAULT_REGION",
      "value": "${var.aws_region}"
    },
    {
      "name": "ENV",
      "value": "${var.env}"
    },
    {
      "name": "TASK_FILE_NAME",
      "value": "${var.task_file_name}"
    }
  ],
  "ulimits": [],
  "resourceRequirements": []
}
CONTAINER_PROPERTIES

}

resource "aws_iam_role" "main" {
  name = local.job_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
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

#### CloudWatch ####

resource "aws_cloudwatch_event_target" "job_schedule" {
  count    = local.deploy_schedule
  rule     = aws_cloudwatch_event_rule.job_schedule[0].name
  arn      = var.job_queue_arn
  role_arn = aws_iam_role.job_schedule_event_target[0].arn

  batch_target {
    job_definition = aws_batch_job_definition.main.arn
    job_name       = "${aws_batch_job_definition.main.name}-${local.schedule_name_pascal_case}"
  }
}

resource "aws_cloudwatch_event_rule" "job_schedule" {
  count               = local.deploy_schedule
  is_enabled          = var.schedule_enabled
  name                = local.schedule_rule_name
  description         = "Schedule for ${aws_batch_job_definition.main.name} job"
  schedule_expression = "cron(${var.schedule_cron})"
}

resource "aws_iam_role" "job_schedule_event_target" {
  count = local.deploy_schedule
  name  = local.schedule_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "job_schedule_event_target_role_aws_batch_submit_job_access" {
  count = local.deploy_schedule
  name  = "aws_batch_submit_job_access"
  role  = aws_iam_role.job_schedule_event_target[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "batch:SubmitJob",
      "Resource": "*"
    }
  ]
}
EOF

}

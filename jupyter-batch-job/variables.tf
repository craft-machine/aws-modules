variable "notebook_parameters" {
  description = "Parameters passed to the notebook via Papermill. Must be entered as terraform \"map\" type. Under the hood is converted into json before passing to Papermill."
  type        = map(string)
  default     = {}
}

variable "notebook_execution_name_pattern" {
  description = "Pattern used to save execution outputs to S3. The most commonly used one is \"{notebook.name}/{execution.timestamp}\""
}

variable "notebook_group_name" {
  description = "Name of top-level grouping for notebooks. Usually it is \"etl\". Other suggestions are \"data_science\", \"data_monitoring\", \"reports\""
  default     = "etl"
}

variable "container_volumes" {
  description = "List of volumes you need to mount." # TODO: Fix type as soon as this issue will be resolved https://github.com/hashicorp/terraform/issues/19898
  type = any
  default = []
}

variable "container_mount_points" {
  description = "List of mount points for provided volumes." # TODO: Fix type as soon as this issue will be resolved https://github.com/hashicorp/terraform/issues/19898
  type        = any
  default     = []
}

variable "notebook_repository_name" {
  description = "Name of git repository. Is used as a part of path to notebook location on S3."
}

variable "notebook_relative_path" {
  description = "Path to notebook inside repository folder that is copied to S3."
}

variable "notebooks_s3_bucket_name" {
  description = "S3 Bucket where jupyter notebooks and executions are stored."
}

variable "job_retry_attempts" {
  description = "Number of retries per job attempt."
  default     = 1
}

variable "job_timeout" {
  description = "Job timeout in seconds. This timeout is per attempt."
  default     = 3600
}

variable "container_vcpus" {
  description = "Number of VCPU allocated to container."
  default     = 1
}

variable "container_memory" {
  description = "Memory size in Megabytes allocated to container."
  default     = 1800
}

variable "env" {
  description = "Environment code, like \"qa\", \"staging\", \"production\""
}

variable "schedule_enabled" {
  description = "(Optional) To temporarily disable schedule, set this to \"false\"."
  default     = true
}

variable "schedule_cron" {
  description = "(Optional) Cron expression, e.g. \"0 2 * * ? *\". If blank the schedule is not created."
  default     = ""
}

variable "schedule_name" {
  description = "(Optional) Name of schedule. Will be used to generate Cloudwatch rule name and Batch Job name. Good values are \"daily\", \"hourly\", \"periodic\", etc."
  default     = "schedule"
}

variable "job_queue_arn" {
  description = "AWS Batch Job Queue ARN."
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "docker_image" {
  description = "Docker image used for job. Image must contain installed papercraft."
  default     = ""
}

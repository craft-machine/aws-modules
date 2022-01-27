variable "container_name" {
  description = "Name of the container. Will be used to name related resources."
}

variable "container_definitions" {
  description = "The ECS task definition data source."
}

variable "ecs_cluster_id" {
  description = "ARN of the ECS cluster."
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
}

variable "subnets" {
  type        = list(string)
  description = "The subnets associated with the task."
}

variable "memory_limit" {
  default     = 1024
  description = "Memory limit for the task. Supported values for Fargate - 512 (0.5GB) and between 1024 (1GB) and 16384 (16GB) in increments of 1024 (1GB)"
}

variable "cpu_limit" {
  default     = 512
  description = "vCPU units limit for the task. 256 units equal to 0.25 vCPU. Supprote values for your memory can be found here https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
}

variable "sqs_queue_name" {
  description = "Queue that will be used for task autoscaling."
}

variable "log_group" {
  description = "AWS CloudWatch LogGroup name"
}

variable "max_capacity" {
  description = "Max tasks for the service"
  default     = 1
}

variable "min_capacity" {
  description = "Min tasks for the service"
  default     = 0
}

variable "capacity_provider" {
  description = "Name of one of the ecs cluster's capacity providers"
  default     = "FARGATE"
}

variable "wait_for_steady_state" {
  description = "If true, Terraform will wait for the service to reach a steady state"
  default     = false
}

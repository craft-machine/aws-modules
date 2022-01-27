variable "container_port" {
  description = "The port on the container to associate with the load balancer."
}

variable "container_name" {
  description = "The name of the container to associate with the load balancer (as it appears in a container definition). Also will be used to name related resource."
}

variable "container_definitions" {
  description = "The ECS task definition data source."
}

variable "vpc_id" {
  description = "VPC that will be used for all resources."
}

variable "subnets" {
  type        = list(string)
  description = "Subnets (e.g. private or public) that will be used for all resources."
}

variable "ecs_cluster_id" {
  description = "ARN of an ECS cluster."
}

variable "ecs_cluster_name" {
  description = "Name of an ECS cluster."
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record."
}

variable "zone_name" {
  description = "The Name of the hosted zone to contain this record."
}

variable "log_group" {
  description = "The name of the log group. If omitted, Terraform will assign a random, unique name."
}

variable "internal" {
  description = "If true, the LB will be internal."
}

variable "cpu_low_alarm_enbaled" {
  description = "If true, enable cpu usage low alarm and autoscaling for this alarm."
  default     = false
}

variable "external_port" {
  description = "The port on which the load balancer is listening. Default 80."
  default     = 80
}

variable "health_check" {
  description = "The destination for the health check request. Default /."
  default     = "/"
}

variable "certificate_arn" {
  description = "SSL arn from aws."
  default     = ""
}

variable "lb_name" {
  description = "Set custom load balancer name."
  default     = ""
}

variable "autoscaling_max_capacity" {
  default = 1
}

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual target"
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, during which no response means a failed health check."
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy."
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "The number of consecutive health check failures required before considering the target unhealthy."
  default     = 3
}

variable "wait_for_steady_state" {
  description = "If true, Terraform will wait for the service to reach a steady state"
  default     = false
}

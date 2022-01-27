variable "api_name" {
}

variable "source_file" {
}

variable "bucket_name" {
}

variable "template_name_suffix" {
}

# CLOUDWATCH ###################################################################

variable "alarm_action_arn" {
}

variable "alarm_period" {
}

variable "alarm_threshold" {
  default = "1"
}

variable "alarm_evaluation_periods" {
  default = "1"
}

variable "alarm_metric_name" {
}

variable "alarm_metric_dimention" {
}

variable "alarm_metric_namespace" {
}

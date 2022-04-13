# Batch Job module
## Usage Example:
```
module "my_job" {
  source = "./batch-job" # Put ref tag corresponding to the version you need

 schedule_enabled                = 0
  job_queue_arn                   = "disabled"
  job_timeout                     = 36000
  env                             = terraform.workspace
  docker_image                    = "758800610010.dkr.ecr.us-east-1.amazonaws.com/task"

  repository_name = local.pipeline_name
  task_name = "compliance"
  task_file_name = "compliance.py"
  parameters = {}
  
  container_vcpus  = 1
  container_memory = 1800 # MiB
  job_timeout      = 7200 # Seconds
  job_queue_arn    = "${data.terraform_remote_state.network.batch_etl_internal_sequential_job_queue_arn}"

  schedule_name                     = "daily"       # (Optional) Name of schedule. Will be used to generate Cloudwatch rule name and Batch Job name. Good values are \"daily\", \"hourly\", \"periodic\", etc.
  schedule_cron                     = "0 2 * * ? *" # (Optional) Remove this line if you don't need scheduling

  env                      = "${terraform.workspace}"
}
```
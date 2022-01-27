# Jupyter Batch Job module
## Usage Example:
```
module "my_job" {
  source = "git::https://bitbucket.org/craftmachine/aws-modules//jupyter-batch-job?ref=428" # Put ref tag corresponding to the version you need

  notebook_relative_path   = "dir/notebook-for-my-job.ipynb" # notebook path, relative to s3 root path where your notebooks are being uploaded
  notebook_repository_name = "my-awesome-reposiory"      # dash-case
  notebook_group_name      = "etl"                       # snake_case, for anything related to data movement put "etl" here

  # Parameters passed to the Notebook via Papermill
  notebook_parameters = {
    ENV              = "${terraform.workspace}"
    DATE_START       = "2019-01-01"
    DATE_END         = "2019-01-02"
    ONE_MORE_PARAM   = "Some Value"
  }

  notebook_execution_name_pattern = "{notebook.name}/{execution.timestamp}"

  container_vcpus  = 1
  container_memory = 1800 # MiB
  job_timeout      = 7200 # Seconds
  job_queue_arn    = "${data.terraform_remote_state.network.batch_etl_internal_sequential_job_queue_arn}"

  schedule_name                     = "daily"       # (Optional) Name of schedule. Will be used to generate Cloudwatch rule name and Batch Job name. Good values are \"daily\", \"hourly\", \"periodic\", etc.
  schedule_cron                     = "0 2 * * ? *" # (Optional) Remove this line if you don't need scheduling


  notebooks_s3_bucket_name = "${data.terraform_remote_state.bi_network.jupyter_notebooks_s3_bucket_name}"
  env                      = "${terraform.workspace}"
}
```

If your notebook needs additional permissions, you can use `job_role_name` output variable from the module to attach your own policies to the role. 

Example:
```
resource "aws_iam_role_policy" "my_policy" {
  name   = "my_policy"
  role   = "${module.my_job.job_role_name}" # Get role name from module
  policy = "${data.aws_iam_policy_document.my_policy.json}"
}

data "aws_iam_policy_document" "my_policy" {
  statement {
    ...
  }
}
```
##################################################################################
# VARIABLES
##################################################################################

variable "num_docker-ep" { default=0 }

variable "hawkeye_manager_ip" {default =""}


#  OTHER

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_session_token" { default = "" }
variable "private_key_with_full_path" {}
variable "key_name" {}

variable "environment_tag" {
  default = "t-hawkeye"
}
variable "owner_tag"      { default ="gustavo.amador-nieto@keysight.com" }
variable "options_tag"    { default = "WEEK" }


variable "my_aws_region" {
  default = "us-east-1"
}

# 4 vCPUs 16G RAM
variable "ManagerType" {
    default = "t2.xlarge"
}

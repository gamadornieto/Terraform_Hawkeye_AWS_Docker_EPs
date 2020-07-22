# Terraform Hawkeye AWS Docker EP example

This is a Keysight lab to automate the deployment of Hawkeye Docker EPs in AWS

## Prerequisites

An already deployed Keysight Hawkeye manager.

## Deploy the infrastructure

 Inside this folder initialise Terraform plugins
terraform init

 Edit file "my_vars.tfvars" and fill/edit the missing info

 ## Deploy the infrastructure

terraform apply --var-file="my_vars.tfvars"

 ## Delete infrastructure

terraform destroy --var-file="my_vars.tfvars"  --force

## License
MIT / BSD

Author Information
Created in 2020 Gustavo AMADOR NIETO.

/*
All AWS Cloud resources must follow naming convention
{Swisscom Zone}-{Team}-{LogicalRequirement}-{CloudResourceType}-{Environemnt}
Or Alternatively;
{BU/Team}-{Product}-{LogicalRequirement}-{CloudResourceType}-{Environemnt}
e.g:
    - rd-cloudops-landing-bucket-dev
    - techenablement-iaws-custdelivery-stream-uat

RD = Rotterdam
RG = Riga
iAWS = Swisscom Laning Zones (Shared in JD)
Assuming CloudOps & Technology Enablement to be teams/depts. at Swisscom DevOps Center
*/

variable "project" {
    type = string
    default = "rd-cloudops"
    description = "The prefix assigned to all resources created for a particular project"
    nullable = false
}

variable "environment" {
    type = string
    default = "dev"
    description = "The postfix assigned to all resources based on environment: dev, stg, qa, uat, prod"
}

variable "sm_trigger_code_filepath" {
    default = "./sm_trigger.py"
}

/*
Defining a local block to apply naming conventions to resources
    - DynamoDB table does not follow the naming convention due to specific naming requirements stated in Assignment
    - S3 Bucket specifically reqiores a globally unique name as an identifier 
*/
locals {
    landing_bucket_name = "${var.project}-landing-bucket-${var.environment}"

    files_table_name  = "Files"

    sm_trigger_funtion_filepath = "./"
    sm_trigger_function_name = "${var.project}-sm-trigger-function-${var.environment}"
    sm_trigger_role_name = "${var.project}-sm-trigger-function-role-${var.environment}"
    sm_trigger_policy_name = "${var.project}-sm-trigger-function-policy-${var.environment}"


    files_statemachine_name = "${var.project}-filename-update-statemachine-${var.environment}"
    files_statemachine_role_name = "${var.project}-filename-update-statemachine-role-${var.environment}"
    files_statemachine_policy_name = "${var.project}-filename-update-statemachine-policy-${var.environment}"
    

    environment = "${var.environment}"   
}



/*
Region to be decided based on
- User base
- Data Source
- Services Availability 
For the purpose of this assignment - assuming all resources to be provisioned inside region "eu-central-1" 
*/
variable "region" {
    type = string
    default = "eu-central-1"
}


/*
Tag enforcement to be enabled for all resources created. 
Currently removing for the sake of simplicity
*/
# variable "tags" {
#     type = object({
#         name = string
#         createdby = string
#         department = string
#         env = string
#         costcenter = number
#     })
# }

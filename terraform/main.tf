
/*
Using "archive_file" Data block to zip Python code to be utilized by AWS Lambda function  
*/
data "archive_file" "python_lambda_packager" {
    type = "zip"
    source_file = "./python/sm_trigger.py"
    output_path = "sm_trigger_function.zip"
}

/*
Assuming this is the landing bucket - following best practices for landing buckets we will have the following configurations
1- Versioning Enabled: Preserves previous versions of files for over-writes to the same S3 Objects
2- S3 SSE Enabled: Enabling S3 provided SSE encryption to offload management overhead. 
    - For high security compliance requirements, we can also utilize KMS keys based encryption, or managing encryption on client side  
3- 
*/

resource "aws_s3_bucket" "landing_bucket" {
    bucket = local.landing_bucket_name

    versioning {
      enabled = true
    }

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
}

/*
Assuming the DynamoDB Table is utilzed to track files uploaded to landing bucket (which can be high in volume) we can go with the following design choices
1- Billing Mode: PAY_PER_REQUEST - This can help us avoid self managing auto-scaling of Read/Write capacities for our table
    - If cost is a constraint, or we have a predictable workload of files loaded to S3, we can go with PROVISIONED option and manage capacity to reduce cost
2- Hash Key: Primary Key attribute utilized by DynamoDB for hashing function for partitioning data
    - We can increase read-performance for our DynamoDB tables by adding additional Sort Key (Range_Key) and using secondary indexes based on access patterns of table
    - Given we only have one attribute, additional configurations are not required
*/
resource "aws_dynamodb_table" "files_table" {
    name = local.files_table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "FileName"
    attribute {
      name = "FileName"
      type = "S"
    }
}

/*
Assumptions and Design Choices here
*/
resource "aws_iam_role" "lambda_function_role" {
    nam = local.sm_trigger_role_name
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]        
    }
    EOF
}


resource "aws_iam_role_policy" "lambda_funtion_policy" {
  name = local.sm_trigger_policy_name
  role = aws_iam_role.lambda_iam.id

  policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": [
            "s3:*",
            "states:StartExecution",
            "lambda:*", 
            "cloudwatch:*" 
        ],
        "Effect": "Allow",
        "Resource": "${aws_sfn_state_machine.filename_update_state_machine.arn}"
        },
        {
        "Action": [
            "s3:*",
            "lambda:*", 
            "cloudwatch:*" 
        ],
        "Effect": "Allow",
        "Resource": "*"
        }

    ]
    }
EOF
}

resource "aws_lambda_function" "file_upload_lambda" {
  filename = "file_upload_lambda.zip"
  function_name = local.sm_trigger_function_name
  role = aws_iam_role.lambda_function_role.arn
  handler = "sm_trigger.lambda_handler"
  runtime = "python3.8"
  environment {
    variables = {
      STATE_MACHINE_ARN = "${aws_sfn_state_machine.filename_update_state_machine}"
    }
  }
  timeout = 30
}


resource "aws_iam_role" "state_machine_role" {
    name = local.sm_trigger_role_name
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "states.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]        
    }
    EOF
}

resource "aws_iam_role_policy" "state_machine_policy" {
  name = local.files_statemachine_policy_name
  role = aws_iam_role.state_machine_role.id

  policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": [
            "dynamodb:PutItem",
        ],
        "Effect": "Allow",
        "Resource": "${aws_dynamodb_table.files_tale.arn}"
        }
    ]
    }
EOF
}

/*
Assumptions and Design Choices here
*/
resource "aws_sfn_state_machine" "filename_update_state_machine" {
    name = local.files_statemachine_name
    definition = jsonencode(
        {
            Comment = "Track files uploaded to S3"
            StartAt = "WriteToDynamoDB"
            States = {
                WriteToDynamoDB = {
                    Type = "Task", 
                    Resource =  "arn:aws:states:::dynamodb:putItem",
                    Parameters = {
                        "TableName": "${aws_dynamodb_table.files_table.name}",
                        "Item": {
                            "FileName": {
                                "S.$": "$.Records[0].s3.object.key"
                            }
                        }
                    },
                    End = true
                }
            }
        }
    )
}



resource "aws_s3_bucket_notification" "bucket_" {
  bucket = aws_s3_bucket.landing_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.landing_bucket.id}"
}
import json
import boto3
import os

sfn_client = boto3.client('stepfunctions', region = 'eu-central-1')
STATE_MACHINE_ARN = os.environ['STATE_MACHINE_ARN']

def lambda_handler(event, context):
    
    #Traversing the Event Trigger i.e S3 PutItem Notification
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        s3_object = {
            "bucket": bucket,
            "key": key
        }
        input = {
            "s3Object": s3_object
        }

        #Using Boto3 client to invoke Step Function state machine
        response = sfn_client.start_execution(
            stateMachineArn=str(STATE_MACHINE_ARN),
            input=json.dumps(input)
        )
        print(response)
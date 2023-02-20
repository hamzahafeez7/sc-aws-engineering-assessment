import json
import boto3
import os


sfn_client = boto3.client('stepfunctions')
STATE_MACHINE_ARN = os.environ['STATE_MACHINE_ARN']

def lambda_handler(event, context):
    
    #Parsing the Event Trigger i.e S3 PutItem Notification
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

        #Parsing the response from State Machine execution
        response_dict = json.loads(response)
        #print(response)

        return_code = response_dict['ResponseMetadata']['StatusCode'] 

        if return_code == 200:
            return {
                'message': 'State Machine successfully executed',
                'code': str(return_code)
            }
        else:
            return {
                'message': 'Unable to execute State Machine. Kindly check configurations',
                'code': str(return_code)
            }
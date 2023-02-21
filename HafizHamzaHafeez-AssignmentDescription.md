
**Swisscom DevOps Center Rotterdam**
  
### Take Home Assignment
  
**Candidate:** Hafiz <ins>Hamza</ins> Hafeez

**Position:** Cloud Platform Engineer

**Submission Date:** February 21, 2023 (Tuesday)


<hr>

<hr>

  

## Purpose

  

The purpose of this document is to provide assumptions, assignment details and decisions taken across the following two assignment tasks;
- CloudFormation Stack 
- Terraform Deployment

  

## Assumptions

  

For this assignment, we shall make the following assumptions to define the scope of deliverables.

  

- Solution will be considered production ready, however codes shall focus on single environment setup (i.e. dev)

- AWS will be the default cloud provider, however, in-built local stack setup and credentials will be utilized for ease of deployment and validations

- Terraform is already installed on the device (VM/Local Device) used for infrastructure deployment. Windows device is considered the default

- Naming Convention for AWS Cloud Resource  

		{Swisscom Zone}-{Team}-{LogicalRequirement}-{CloudResourceType}-{Environemnt}
	Or Alternatively

		{BU/Team}-{Product}-{LogicalRequirement}-{CloudResourceType}-{Environemnt}

	**Examples**

		- rd-cloudops-landing-bucket-dev (S3 Bucket)

		- techenablement-iaws-custdelivery-stream-uat (Kinesis Data Stream)


	RD = Rotterdam
	RG = Riga
	iAWS = Swisscom Laning Zones (Shared in JD)

	Assuming CloudOps & Technology Enablement to be teams/depts. at Swisscom DevOps Center
  
  

-----

## Task 1 -  **CloudFormation Stack**


 
### **Resources:**


**1-S3 Bucket**  

- Default bucket provided without and specific configurations
- Requirements shared via CFN-NAG logs

	- S3 Bucket Policy   - Requires additional resource "S3BucketPolicy"	
	- Access Logging Configuration - Requires additional "S3LoggingBucket" along with property "LoggingConfigurations"
	- S3 Encryption - SSE-S3 encryption enabled using property "BucketEncryption" and enforced using S3 Bucket Policy

**2-S3 Bucket Policy**

-	Creates an S3 Bucket policy that only allows S3 Uploads to bucket with SSE-S3 encryption enabled
-	Requires header field "s3:x-amz-server-side-encryption" to be "AES256" for all "s3:PutObject" requests
-	Additional security can be enabled using SSE-KMS encryption

**3-S3 Logging Bucket**

-	S3 Bucket used for logging purposes 
-	A more simpler approach could have used different  same bucket however simple error in architecture and development can lead to an infinite loop of objects, hence alternate approach taken.
  
---
---

## Task 2 - **Terraform Serverless Deployment**
  

### **Key Resources:**

  
**1-S3 Landing Bucket**
Assuming this is the landing bucket - following best practices for landing buckets we will have the following configurations:

 - Versioning Enabled: Preserves previous versions of files for over-writes to the same S3 Objects
 - S3 SSE Enabled: Enabling S3 provided SSE encryption to offload management overhead. (For high security compliance requirements, we can also utilize KMS keys based encryption, or managing encryption on client side)
 

**2-Lambda Function**
  
-	Lambda function utilized Python 3.8 runtime
-	State Machine ARN is passed to Lambda function using environment variables
-	The python code utilizes Boto3 SDK - Step Function client to invoke the state machine
-	The Lambda function is triggered using S3 Bucket Notification (s3:ObjectCreated)
-	Additionally the Lambda function requires definition of Lambda Permission which allows S3 Event to invoke the Lambda function
-	Once executed, it proceeds to;

	- Parse the Event Trigger JSON for S3 Object Key
	- Use Environment Variables for State Machine Identifier
	- Uses Step Function client's "start_execution" method to invoke the state machine
	- Evaluates the response from State Machine and logs the output to CloudWatch Logs accordingly (In production scale workflow, we shall add a highly robust Error Handling logic along)
	
 **3-Step Function - State Machine**

 Following design choices should be considered for Production Grade State Machine of similar workload

-	Add separate states for Start (Pass State), PutItem and End (Pass) for separation of concerns
-	Add a **retry policy** using Retry block which could be used with **exponential backoff**
-	Add **Error Handling** logic using Catch Block and transition the state to an alternate state that;

	-	Adds CloudWatch Logs regarding failure
	-	Sends out SNS Notification regarding failure
	-	Passes the Object-Key into a Dead-Letter Queue in SQS (To be polled by separate failsafe workflow e.g. Lambda Function for adding items into DynamoDB Table)

**Disclaimer:** For the sake of simplicity and due to time constraints, the above provided state machine does not include these configurations 

 **4-DynamoDB Table - Files Table**
Although we utilize a very simplistic approach, assuming the DynamoDB Table is utilized to track files uploaded to landing bucket (which can be high in volume) we can go with the following design choices;

 - **Billing Mode:** PAY_PER_REQUEST - This can help us avoid self managing auto-scaling of Read/Write capacities 
	-	If cost is a constraint, or we have a predictable workload of files loaded to S3, we can go with PROVISIONED option and manage capacity to reduce cost

-	**Hash Key:** Primary Key attribute utilized by DynamoDB for hashing function for partitioning data

	-	We can increase read-performance for our DynamoDB tables by adding additional Sort Key (Range_Key) and using secondary indexes based on access patterns of table
	-	 Given we only have one attribute, additional configurations are not required
  
  

**NOTE:** The Terraform assignment code ran into Lambda Execution errors  which I was unable to replicate on personal AWS Account. Due to time constraints (along with personal and professional commitments) further debugging will be carried out in upcoming days and can be discussed while reviewing the assignment during Speed Dating Session.
  
---
---

<center> End of Assignment</center>

<center> Thanks and Regards </center>

  
---
---
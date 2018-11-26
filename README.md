# BLJBatchAWS
This is a series of batch scripts that deploys an AWS Batch compute environment suitable for use with the BioLockJ Genomics analysis pipeline.  

To run:

1.) Make sure docker, awscli, and git are installed on your computer or virtual environment (macOS or Linux only for now).

2.) Create an Amazon Web Services Account and create a root key pair.  Write them down, as you will not be able to retrieve them later.

3.) Run the following command from a command prompt to login to your AWS account from the console

**Note, this currently creates a custom sized AMI which will use storage space and create charges to your AWS account. Delete this AMI and all associated volume snapshots when you are done.**  This is for developent purposes, in the future a publicly available AMI will be provided.
```
aws configure
AWS Access Key ID []:myaccesskeyID
AWS Secret Access Key []:mysecretaccesskey
Default region name []:us-east-1
Default output format []:text
```
4.) run the following commands to deploy a computing environment and all associated AWS resources necessary for submitting AWS Batch computing jobs.
```
git clone https://github.com/mjzapata/BLJBatchAWS.git
cd BLJBatchAWS
./deployBLJBatchEnv.sh
```
5.) Install Nextflow and create a nextflow configuration file that specifies the Batch service role that was created during the compute environment startup.


## AWS Batch Environment
#### AMI - Amazon Machine Image
	-This is a custom virtual machine which contains Docker and some of the pre-requisite software for Nextflow, including AWSCLI
#### AWS Batch Compute Environment:
	-maximum vCPUs (virtual CPUs)
	-Amazon Machine Image (AMI) definition or creation
	-Spot Price – the percent at which to bid on available EC2 instances
#### AWS Batch Job Queue:
	-defines the priority
	-one or more compute environments
#### AWS Batch Job definitions: 
	-defines Docker images and scripts
	-defines how jobs are run
	-defines the memory and vCPU requirements which are used to determine the optimal EC2 instance type for that particular job.
#### AWS Batch Jobs:
	-an instance of a job definition, typically for a single sample


## Resource Management
#### Nextflow:
	-Connects directly to the AWS Batch API
	-Manages AWS Batch job definition creation
	-Manages job creation and error handling
#### IAM – Identity and Access Management:
Each AWS resource listed above requires a service role that has the corresponding permissions to use the services necessary for its function.  The main concern is to isolate the batch compute EC2 instances into a network with limited network connectivity while allowing the head node instance to serve its web facing portal.

## Storage and Networking
#### EBS - Elastic Block Store
	-EC2 instance storage for each separate instance
#### EFS - Elastic File System
	-shared storage between instances for short-term results storage
#### S3 – Simple Storage Service
	-Globally unique bucket name for long-term results storage
### Networking:
#### Virtual Private Cloud
#### Security Group
#### Subnet



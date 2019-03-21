# AWSBatchGenomicsStack
This is a series of batch scripts that deploys an AWS Batch compute environment suitable for use with the BioLockJ Genomics analysis pipeline.  

To run:

1.) Make sure docker, awscli, and git are installed on your computer or virtual environment (macOS or Linux only for now).

2.) Create an Amazon Web Services Account and create a root key pair.  Write them down or store them somewhere secure, as you will not be able to retrieve them later.

      -Go to this page and select "Access Keys": https://console.aws.amazon.com/iam/home?#/security_credentials 

3.) Run the following command from a command prompt to login to your AWS account from the console

```
aws configure
AWS Access Key ID []:myaccesskeyID
AWS Secret Access Key []:mysecretaccesskey
Default region name []:us-east-1
Default output format []:text
```
4.) run the following commands to deploy a computing environment and all associated AWS resources necessary for submitting AWS Batch computing jobs.
**Note, this step currently creates a custom sized AMI which will use storage space and create charges to your AWS account. Delete this AMI and all associated volume snapshots when you are done.**  This is for developent purposes, in the future a publicly available AMI will be provided.
```
git clone https://github.com/mjzapata/AWSBatchGenomicsStack.git
cd AWSBatchGenomicsStack
./installBatchDeployer.sh pwd

STACKNAME=mystackname
s3Tools.sh $STACKNAME create
OR s3Tools.sh $STACKAME create globallyuniques3bucketname

source ~/.batchawsdeploy/config
deployBatchEnv.sh create $STACKNAME mydockerhubreponame1
```
5.) Install Nextflow and create a nextflow configuration file that specifies the Batch service role that was created during the compute environment startup.


## AWS Batch Environment
#### AMI - Amazon Machine Image
  -This is a custom virtual machine which contains Docker and some of the pre-requisite software for Nextflow, including AWSCLI blah blah blah blah blah <br />
#### AWS Batch Compute Environment:
  -maximum vCPUs (virtual CPUs) <br />
  -Amazon Machine Image (AMI) definition or creation <br />
  -Spot Price – the percent at which to bid on available EC2 instances <br />
#### AWS Batch Job Queue:
  -defines the priority <br />
  -one or more compute environments <br />
#### AWS Batch Job definitions: 
  -defines Docker images and scripts <br />
  -defines how jobs are run <br />
  -defines the memory and vCPU requirements which are used to determine the optimal EC2 instance type for that particular job. <br />
#### AWS Batch Jobs:
  -an instance of a job definition, typically for a single sample <br />
## Resource Management
#### Nextflow:
-Connects directly to the AWS Batch API <br />
-Manages AWS Batch job definition creation <br />
-Manages job creation and error handling <br />
#### IAM – Identity and Access Management:
Each AWS resource listed above requires a service role that has the corresponding permissions to use the services necessary for its function.  The main concern is to isolate the batch compute EC2 instances into a network with limited network connectivity while allowing the head node instance to serve its web facing portal. <br />

## Storage and Networking
#### EBS - Elastic Block Store
  -EC2 instance storage for each separate instance <br />
#### EFS - Elastic File System
  -shared storage between instances for short-term results storage <br />
#### S3 – Simple Storage Service
  -Globally unique bucket name for long-term results storage <br />
### Networking:
<br />
#### Virtual Private Cloud
<br />
#### Security Group
<br />
#### Subnet
<br />


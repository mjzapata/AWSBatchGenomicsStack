#!/bin/bash

#TODO: Test that the IP addresss is getting assigned correctly
#TODO: test that S3 is getting created correctly in both cases

#need to capture output from each step and check for success?

#also check if there are currently any instances using any of these resources?
#get the ID and tell them to run the shutdown
#AWS_PROFILE=batchcompute

#PATH=$PATH:~/Documents/github/aws/AWSBatchGenomicsStack
#PATH=$PATH:~/Documents/github/aws/AWSBatchGenomicsStack/support

if [ ! -f "~/.batchawsdeploy/config" ]; then
    echo "~/.batchawsdeploy/config does not exist"
    echo "did you run installBatchDeployer.sh?"
    exit 1
fi
source ~/.batchawsdeploy/config

ARGUMENT=$1

print_help() {
    echo "-This script deploys an Amazon Web Services (AWS) cloudformation stack and 
    other resources necessary for using AWS Batch.  This script also saves the
    configuration of this stack to the local hidden directories:
    \"~/.aws/\" and \"~/.nextflow/\""
    echo "-The dockerhub repository name creates the priviledged job definitions
    for nextflow.  These are necessary for EFS mounts. For multuple docker hub 
    repositories use the | pipe operator WITH QUOTES as shown below."
    echo "Run this command to test your results: docker search mydockerhubreponame | grep -E mydockerhubreponame"
    echo ""
    echo "-When the resources are no longer needed, run the delete command."
    echo "MYSTACKNAME must be alphanumeric.  No underscores."
    echo ""
    echo "Usage: deployBatchEnv.sh help"
    echo "Usage: deployBatchEnv.sh create MYSTACKNAME mydockerhubreponame1 autogenerate"
    echo "Usage: deployBatchEnv.sh create MYSTACKNAME mydockerhubreponame1 MYS3BUCKETNAME"
    echo -n "Usage: deployBatchEnv.sh create MYSTACKNAME "
    echo "\"mydockerhubreponame1|mydockerhubreponame2|mydockerhubreponame3\" MYS3BUCKETNAME"
    echo "Usage: deployBatchEnv.sh delete MYSTACKNAME"
    echo ""
}

echo "ARGUMENT: $ARGUMENT"

if [ "$ARGUMENT" == "help" ] || [ "$ARGUMENT" == "--help" ] || [ "$ARGUMENT" == "-h" ]; then
    print_help
else
    if [ "$ARGUMENT" == "create" ] || [ "$ARGUMENT" == "delete" ]; then
        STACKNAME=$2

        # Job Definition
        DOCKERREPOSEARCHSTRING=$3
        S3BUCKETNAME=$4
        DOCKERRREPOVERSION="latest"
        JOBVCPUS=2      #can be overridden at runtime
        JOBMEMORY=1000  #can be overriden at runtime

        COMPUTEENVIRONMENTNAME=${STACKNAME}ComputeEnv
        QUEUENAME=${STACKNAME}Queue
        SPOTPERCENT=80
        MAXCPU=1024
        EBSVOLUMESIZEGB=0

        REGION=us-east-1

        CUSTOMAMIFOREFS="no"
        EFSPERFORMANCEMODE=maxIO  #or generalPurpose

        NEXTFLOWCONFIGOUTPUTDIRECTORY=~/.nextflow/
        mkdir -p $NEXTFLOWCONFIGOUTPUTDIRECTORY
        #AWS_HOME
        AWSCONFIGOUTPUTDIRECTORY=~/.aws/
        mkdir -p $AWSCONFIGOUTPUTDIRECTORY

        KEYNAME=${STACKNAME}KeyPair

        #Can check if this file already exists before proceeding?
        AWSCONFIGFILENAME=${BATCHAWSDEPLOY_HOME}${STACKNAME}.sh
        echo "AWSCONFIGFILENAME=$AWSCONFIGFILENAME"

        #S3 buckets will NOT be deleted when running "deployBLJBatchEnv delete"
        #autogenerate is a keyword that creates a bucket named ${STACKNAME}{randomstring}, eg Stack1_oijergoi4itf94j94

    	if [ "$ARGUMENT" == "create" ] && [ $# -eq 4 ]; then
            
            #DEFAULTAMI=ami-06bec82fb46167b4f #IMAGES
            echo "Finding Latest Amazon Linux AMI ID..."
            #TODO: if is-empty, set a default, in case this breaks in the future. 
            DEFAULTAMI=$(getLatestAMI.sh $REGION amzn2-ami-ecs-hvm 2019 x86_64)
            echo "DEFAULTAMI=$DEFAULTAMI"
            echo ""

            #Create AWS config file and start writing values
            touch "$AWSCONFIGFILENAME"
            echo "#!/bin/bash" > $AWSCONFIGFILENAME
            echo "" >> $AWSCONFIGFILENAME
            echo "AWSCONFIGFILENAME=$AWSCONFIGFILENAME" >> $AWSCONFIGFILENAME
            #echo "AWS_PROFILE=$AWS_PROFILE" >> $AWSCONFIGFILENAME
            echo "DOCKERREPOSEARCHSTRING=\"$DOCKERREPOSEARCHSTRING\"" >> $AWSCONFIGFILENAME
            echo "DOCKERRREPOVERSION=$DOCKERRREPOVERSION" >> $AWSCONFIGFILENAME
            echo "JOBVCPUS=$JOBVCPUS" >> $AWSCONFIGFILENAME
            echo "JOBMEMORY=$JOBMEMORY" >> $AWSCONFIGFILENAME
            echo "NEXTFLOWCONFIGOUTPUTDIRECTORY=$NEXTFLOWCONFIGOUTPUTDIRECTORY" >> $AWSCONFIGFILENAME

    	   createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE $AWSCONFIGOUTPUTDIRECTORY \
                    $NEXTFLOWCONFIGOUTPUTDIRECTORY $REGION $KEYNAME $S3BUCKETNAME

    	elif [ "$ARGUMENT" == "delete" ] && [ $# -eq 2 ]; then
            echo "this will take approximately three minutes"
            echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
            
            source $AWSCONFIGFILENAME
            # TODO: check for running EC2 instances
            # aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0fb51f0752d394c02,
            # research how to use query vs filter: 
            # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-network-interfaces.html
            # DESCRIPTION
            # Network interface for Bastion Node
            # EFS mount target for fs-56d23cb6 (fsmt-42d00fa3)
            echo "deleting job queue $QUEUENAME"
            aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
            sleepProgressBar.sh 5 5
            aws batch delete-job-queue --job-queue $QUEUENAME
            sleepProgressBar.sh 5 8
            #delete compute environment which is dependent on queue
            echo "deleting compute environment $COMPUTEENVIRONMENTNAME"
            aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
            sleepProgressBar.sh 5 6
            aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
            sleepProgressBar.sh 5 8
            #delete cloudformation stack

            #delete job definition
            # aws batch deregister-job-definition 
            # get a list of all jobdefs that start with $STACKNAME
            echo "deleting cloudformation stack $STACKNAME"
            aws cloudformation delete-stack --stack-name $STACKNAME
            sleepProgressBar.sh 6 10
            awskeypair.sh delete $KEYNAME

            rm $AWSCONFIGFILENAME
            rm ${NEXTFLOWCONFIGOUTPUTDIRECTORY}config
        else
            print_help
    	fi
    else
        print_help
    fi
fi



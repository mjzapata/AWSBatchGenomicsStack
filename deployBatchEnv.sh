#!/bin/bash

#TODO: Test that the IP addresss is getting assigned correctly
#TODO: test that S3 is getting created correctly in both cases

#need to capture output from each step and check for success?

#also check if there are currently any instances using any of these resources?
#get the ID and tell them to run the shutdown
#AWS_PROFILE=batchcompute

#1.) CHECK THAT INSTALL SCRIPT HAS BEEN RUN
if [ ! -f ~/.batchawsdeploy/config ]; then
    echo "~/.batchawsdeploy/config does not exist"
    echo "did you run installBatchDeployer.sh?"
    exit 1
fi
source ~/.batchawsdeploy/config

#2.) CHECK AWS VERSION
#https://stackoverflow.com/questions/19915452/in-shell-split-a-portion-of-a-string-with-dot-as-delimiter
#https://stackoverflow.com/questions/2342826/how-to-pipe-stderr-and-not-stdout
#aws-cli/1.16.25  Python/2.7.15rc1 Linux/4.9.125-linuxkit botocore/1.12.15 (OUTDATED)
#aws-cli/1.16.114 Python/2.7.16rc1 Linux/4.9.125-linuxkit botocore/1.12.104
versions=$(aws --version 2>&1 >/dev/null) # | grep -o '[^-]*$')
echo "versions=$versions"
awsversion=$(echo $versions | cut -d ' ' -f1 | cut -d '/' -f2)
echo "current aws-cli version:  $awsversion"
awsmajor=$(echo $awsversion | cut -d. -f1); awsmajor_required=1
awsminor=$(echo $awsversion | cut -d. -f2); awsminor_required=16
awsmicro=$(echo $awsversion | cut -d. -f3); awsmicro_required=65

if [ $(expr $awsmajor) -lt $awsmajor_required ] || \
    [ $(expr $awsminor) -lt $awsminor_required ] || \
    [ $(expr $awsmicro) -lt $awsmicro_required ]; then
    echo -n "minimum required version: "
    echo "${awsmajor_required}.${awsminor_required}.${awsmicro_required}"
    echo "aws command line tool outdated. please update."
    echo "type \"aws --version\" for more information"
    exit 1
fi

#TODO:
#CHECK AWS CREDENTIALS
#aws s3 ls  "Authorization"  "Credentials"

#3.) CHECK AWS CREDENTIALS
testCredentials=$(aws iam get-user) 
error=$?
if [ $error != 0 ]; then
    echo "AWS credentials error code: $error"
    echo $testCredentials
    exit 1
fi


ARGUMENT=$1

print_help() {
    echo "-This script deploys an Amazon Web Services (AWS) cloudformation stack and 
    other resources necessary for using AWS Batch.  This script also saves the
    configuration of this stack to the local hidden directories:
    \"~/.batchawsdeploy/\", \"~/.aws/\", and \"~/.nextflow/\""
    echo "-The dockerhub repository name creates the priviledged job definitions
    for nextflow.  These are necessary for EFS mounts. For multuple docker hub 
    repositories use the | pipe operator WITH QUOTES as shown below."
    echo "Run this command to test your results: docker search mydockerhubreponame | grep -E mydockerhubreponame"
    echo ""
    echo "-When the resources are no longer needed, run the delete command."
    echo "MYSTACKNAME must be alphanumeric.  No underscores."
    echo ""
    echo "Usage: deployBatchEnv.sh help"
    echo "Usage: deployBatchEnv.sh create MYSTACKNAME mydockerhubreponame1" #autogenerate"
    echo "Usage: deployBatchEnv.sh create MYSTACKNAME mydockerhubreponame1" #MYS3BUCKETNAME"
    echo -n "Usage: deployBatchEnv.sh create MYSTACKNAME "
    echo "\"mydockerhubreponame1|mydockerhubreponame2|mydockerhubreponame3\"" #MYS3BUCKETNAME"
    echo "Usage: deployBatchEnv.sh delete MYSTACKNAME"
    echo ""
    exit 1
}

echo "ARGUMENT: $ARGUMENT"

if [ "$ARGUMENT" == "help" ] || [ "$ARGUMENT" == "--help" ] || [ "$ARGUMENT" == "-h" ]; then
    print_help
else
    if [ "$ARGUMENT" == "create" ] || [ "$ARGUMENT" == "delete" ]; then
        STACKNAME=$2
        echo "STACKNAME: $STACKNAME"

        # Job Definition
        DOCKERREPOSEARCHSTRING=$3
        
        #optional S3BUCKETNAME if it isn't created beforehand
        S3BUCKETNAME=$4
        
        DOCKERRREPOVERSION="latest"
        JOBVCPUS=2      #can be overridden at runtime
        JOBMEMORY=1000  #can be overriden at runtime

        COMPUTEENVIRONMENTNAME=${STACKNAME}ComputeEnv
        QUEUENAME=${STACKNAME}Queue
        SPOTPERCENT=80
        MAXCPU=1024
        EBSVOLUMESIZEGB=0

        REGION=$(aws configure get region)

        CUSTOMAMIFOREFS="no"
        EFSPERFORMANCEMODE=maxIO  #or generalPurpose

        NEXTFLOWCONFIGOUTPUTDIRECTORY=~/.nextflow/
        mkdir -p $NEXTFLOWCONFIGOUTPUTDIRECTORY
        #AWS_HOME
        AWSCONFIGOUTPUTDIRECTORY=~/.aws/
        mkdir -p $AWSCONFIGOUTPUTDIRECTORY

        KEYNAME=${STACKNAME}
        KEYPATH=~/.batchawsdeploy/key_${KEYNAME}.pem

        #Can check if this file already exists before proceeding?
        BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
        echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE"

        #S3 buckets will NOT be deleted when running "deployBLJBatchEnv delete"
        #autogenerate is a keyword that creates a bucket named ${STACKNAME}{randomstring}, 
        #    eg. Stack1_oijergoi4itf94j94

    	if [ "$ARGUMENT" == "create" ] && [ $# -gt 2 ] && [ $# -lt 5 ]; then
            
            #DEFAULTAMI=ami-06bec82fb46167b4f #IMAGES
            echo "Finding Latest Amazon Linux AMI ID..."
            #TODO: if is-empty, set a default, in case this breaks in the future. 
            DEFAULTAMI=$(getLatestAMI.sh $REGION amzn2-ami-ecs-hvm 2019 x86_64)
            echo "DEFAULTAMI=$DEFAULTAMI"
            echo ""

            #Create AWS config file and start writing values
            #this is duplicated in s3Tools.sh and deployBatchEnv.sh
            if [ ! -f $BATCHAWSCONFIGFILE ]; then
                touch "$BATCHAWSCONFIGFILE"
                echo "#!/bin/bash" > $BATCHAWSCONFIGFILE
                echo "" >> $BATCHAWSCONFIGFILE
                echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE" >> $BATCHAWSCONFIGFILE
                echo "REGION=$REGION" >> $BATCHAWSCONFIGFILE
            fi

            #echo "AWS_PROFILE=$AWS_PROFILE" >> $BATCHAWSCONFIGFILE
            echo "DOCKERREPOSEARCHSTRING=\"$DOCKERREPOSEARCHSTRING\"" >> $BATCHAWSCONFIGFILE
            echo "DOCKERRREPOVERSION=$DOCKERRREPOVERSION" >> $BATCHAWSCONFIGFILE
            echo "JOBVCPUS=$JOBVCPUS" >> $BATCHAWSCONFIGFILE
            echo "JOBMEMORY=$JOBMEMORY" >> $BATCHAWSCONFIGFILE
            echo "NEXTFLOWCONFIGOUTPUTDIRECTORY=$NEXTFLOWCONFIGOUTPUTDIRECTORY" >> $BATCHAWSCONFIGFILE

          echo "COMMAND BEING RUN: createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE $AWSCONFIGOUTPUTDIRECTORY \
                    $NEXTFLOWCONFIGOUTPUTDIRECTORY $KEYNAME"
    	   createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE $AWSCONFIGOUTPUTDIRECTORY \
                    $NEXTFLOWCONFIGOUTPUTDIRECTORY $KEYNAME

    	elif [ "$ARGUMENT" == "delete" ] && [ $# -gt 1 ]; then
            echo "this will take approximately three minutes"
            echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
            
            source $BATCHAWSCONFIGFILE
            # TODO: check for running EC2 instances
            instanceFiles=~/.batchawsdeploy/instance_${STACKNAME}*
            instanceFiles=(~/.batchawsdeploy/instance_${STACKNAME}*)

            # aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0fb51f0752d394c02,
            # research how to use query vs filter: 
            # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-network-interfaces.html
            # DESCRIPTION
            # Network interface for Bastion Node
            # EFS mount target for fs-56d23cb6 (fsmt-42d00fa3)
            echo "deleting job queue $QUEUENAME"
            aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
            sleepProgressBar.sh 5 6
            aws batch delete-job-queue --job-queue $QUEUENAME
            sleepProgressBar.sh 5 9
            #delete compute environment which is dependent on queue
            echo "deleting compute environment $COMPUTEENVIRONMENTNAME"
            aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
            sleepProgressBar.sh 5 6
            aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
            sleepProgressBar.sh 5 9
            #delete cloudformation stack

            #delete job definition
            # aws batch deregister-job-definition 
            # get a list of all jobdefs that start with $STACKNAME
            echo "deleting cloudformation stack $STACKNAME"
            aws cloudformation delete-stack --stack-name $STACKNAME
            sleepProgressBar.sh 6 10
            awskeypair.sh delete $KEYNAME

            rm $BATCHAWSCONFIGFILE
            #rm ${NEXTFLOWCONFIGOUTPUTDIRECTORY}config
        else
            print_help
    	fi
    else
        print_help
    fi
fi



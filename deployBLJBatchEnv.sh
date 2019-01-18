#!/bin/bash

#TODO: add progress bar
#need to capture output from each step and check for success?
#also check if there are currently any instances using any of these resources?

ARGUMENT=$1

STACKNAME=$2
COMPUTEENVIRONMENTNAME=${STACKNAME}ComputeEnv
QUEUENAME=${STACKNAME}Queue
SPOTPERCENT=40
MAXCPU=1024
EBSVOLUMESIZEGB=0

#hardcoded AMI value. set equal to "no" to create and use custom AMI size
#DEFAULTAMI=no #no
#DEFAULTAMI=ami-021c52fde2e3ab958 #no
DEFAULTAMI=ami-05422e32bf76f947c

CUSTOMAMIFOREFS="no"
EFSPERFORMANCEMODE=maxIO  #or generalPurpose
#DOCKERREPOSEARCHSTRING="biolockj/"
DOCKERREPOSEARCHSTRING="mjzapata2/"

#NEXTFLOWCONFIGOUTPUTDIRECTORY="$HOME/Documents/github/aws/BLJBatchAWS/nextflow/testnextflow"
NEXTFLOWCONFIGOUTPUTDIRECTORY="./nextflow/testnextflow"
mkdir -p $NEXTFLOWCONFIGOUTPUTDIRECTORY

#S3 buckets will NOT be deleted when running "./deployBLJBatchEnv delete"
S3BUCKETNAME=autogenerate #autogenerate #autogenerate is a keyword that creates a bucket named ${STACKNAME}{randomstring}, eg Stack1_oijergoi4itf94j94

if [ $# -eq 2 ]; then

	if [ "$ARGUMENT" == "create" ]; then
	   ./createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE $DOCKERREPOSEARCHSTRING $NEXTFLOWCONFIGOUTPUTDIRECTORY $S3BUCKETNAME

	elif [ "$ARGUMENT" == "delete" ]; then

        echo "this will take approximately three minutes"
        echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
        
        #delete queue
        #echo "|------|"
        #echo -n "<."
        aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
        ./sleepProgressBar.sh 5 5
        aws batch delete-job-queue --job-queue $QUEUENAME
        ./sleepProgressBar.sh 5 8
        #delete compute environment which is dependent on queue
        aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
        ./sleepProgressBar.sh 5 6
        aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
        ./sleepProgressBar.sh 5 8
        #delete cloudformation stack

        #delete job definition
        # aws batch deregister-job-definition 
        # get a list of all jobdefs that start with $STACKNAME

        aws cloudformation delete-stack --stack-name $STACKNAME
        ./sleepProgressBar.sh 6 10

    else
        echo "set the name of your stack inside this script"
        echo "Usage: ./deployBLJBatchEnv.sh create STACKNAME"
        echo "Usage: ./deployBLJBatchEnv.sh delete STACKNAME"

	fi
else
    echo "Usage: ./deployBLJBatchEnv.sh create STACKNAME"
    echo "Usage: ./deployBLJBatchEnv.sh delete STACKNAME"
fi



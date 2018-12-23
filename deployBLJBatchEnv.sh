#!/bin/bash

#TODO: add progress bar
#need to capture output from each step and check for success?
#also check if there are currently any instances using any of these resources?

STACKNAME=BLJStack8
COMPUTEENVIRONMENTNAME=BLJComputeEnvironment8
QUEUENAME=BLJQueue8
SPOTPERCENT=60
MAXCPU=1024
EBSVOLUMESIZEGB=30
#hardcoded AMI value. set equal to "no" to create and use custom AMI size
DEFAULTAMI=ami-021c52fde2e3ab958 #no
#CREATENEWAMI=yes
CUSTOMAMIFOREFS="yes"
EFSPERFORMANCEMODE=maxIO  #or generalPurpose 

if [ $# -eq 1 ]; then
    ARGUMENT=$1

	if [ "$ARGUMENT" == "create" ]; then
	   ./createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE

	elif [ "$ARGUMENT" == "delete" ]; then

        echo "this will take approximately two minutes"
        echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
        
        #delete queue
        #echo "|------|"
        #echo -n "<."
        aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
        sleep 30
        #echo -n "."
        aws batch delete-job-queue --job-queue $QUEUENAME
        sleep 40
        #echo -n "."
        #delete compute environment which is dependent on queue
        aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
        sleep 20
        #echo -n "."
        aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
        sleep 20
        #echo -n "."
        #delete cloudformation stack


        #delete EFS mount point

        #delete EFS

        #delete job definition
        # aws batch deregister-job-definition 

        aws cloudformation delete-stack --stack-name $STACKNAME
        sleep 30
        #echo ".>"

    else
        echo "set the name of your stack inside this script"
        echo "Usage: ./deployBLJBatchEnv.sh create"
        echo "Usage: ./deployBLJBatchEnv.sh delete"

	fi
else
    echo "set the name of your stack inside this script"
    echo "Usage: ./deployBLJBatchEnv.sh create"
    echo "Usage: ./deployBLJBatchEnv.sh delete"
fi


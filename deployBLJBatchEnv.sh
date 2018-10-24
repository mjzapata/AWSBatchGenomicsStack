#!/bin/bash

STACKNAME=BLJStack
COMPUTEENVIRONMENTNAME=BLJComputeEnvironment
QUEUENAME=BLJQueue
SPOTPERCENT=60
MAXCPU=1024
EBSVOLUMESIZEGB=60

if [ $# -eq 1 ]; then
    ARGUMENT=$1

	if [ "$ARGUMENT" == "create" ]; then

	   ./createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU $EBSVOLUMESIZEGB

	elif [ "$ARGUMENT" == "delete" ]; then

        echo "this will take approximately two minutes "
        echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME "
        
        #delete queue
        aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
        sleep 20
        aws batch delete-job-queue --job-queue $QUEUENAME
        sleep 30

        #delete compute environment which is dependent on queue
        aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
        sleep 20
        aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
        sleep 20
        #delete cloudformation stack
        aws cloudformation delete-stack --stack-name $STACKNAME
        sleep 30

    else
        echo "set the name of your stack inside this script "
        echo "Usage: ./deployBLJBatchEnv.sh create "
        echo "Usage: ./deployBLJBatchEnv.sh delete "

	fi

else
    echo "set the name of your stack inside this script "
    echo "Usage: ./deployBLJBatchEnv.sh create "
    echo "Usage: ./deployBLJBatchEnv.sh delete "

fi

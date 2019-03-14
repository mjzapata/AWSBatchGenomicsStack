#!/bin/bash

ARGUMENT1=$1
ARGUMENT2=$2
RESOURCENAME=$3

source ~/.batchawsdeploy/config

print_error(){
	echo -n "Description: this script is used for creating, deleting and querying"
	echo "the status of AWS batch compute environments and job queues"
	echo "Usage:
	batchTools.sh queue [ARGUMENT2] [RESOURCENAME]
	batchTools.sh compute [ARGUMENT2] [RESOURCENAME]
		options for ARGUMENT2: state, status, statusreason, disable, delete, disableAndDelete
	"
	echo "$1"
}

if [ $# -eq 3 ]; then
	if [ "$ARGUMENT1" == "queue" ]; then
		if [ "$ARGUMENT2" == "state" ] || [ "$ARGUMENT2" == "status" ] || [ "$ARGUMENT2" == "statusreason" ]; then
			stateString=$(aws batch describe-job-queues \
			--query 'jobQueues[*].[jobQueueName,state,status,statusReason]' \
			| grep "$RESOURCENAME")
			state=$(echo "$stateString" | awk '{print $2}')
			status=$(echo "$stateString" | awk '{print $3}')
			statusreason=$(echo "$stateString" | awk '{print $4 $5 $6 $7}')

			if [ "$ARGUMENT2" == "state" ]; then
				if [ -z $state ]; then
					echo "NO_SUCH_QUEUE"
				else
					echo "$state"
				fi
			elif [ "$ARGUMENT2" == "status" ]; then
				echo "$status"
			elif [ "$ARGUMENT2" == "statusreason" ]; then
				echo "$statusreason"
			fi
		elif [ "$ARGUMENT2" == "disable" ]; then
			echo "disable queue"
			aws batch update-job-queue --job-queue $RESOURCENAME --state DISABLED
		elif [ "$ARGUMENT2" == "delete" ]; then
			aws batch delete-job-queue --job-queue $RESOURCENAME
		elif [ "$ARGUMENT2" == "disableAndDelete" ]; then
			batchTools.sh queue disable $RESOURCENAME
			STATE=$(batchTools.sh queue state $RESOURCENAME)
			STATUS=$(batchTools.sh queue state $RESOURCENAME)
	        #while [ "$STATE" != "DISABLED" ] || [ "$STATE" != "UPDATING" ] || [ "$STATE" != "NO_SUCH_QUEUE" ]
	        while [ "$STATUS" == "UPDATING" ] 
	        do
	            STATE=$(batchTools.sh queue state $RESOURCENAME)
	            STATUS=$(batchTools.sh queue state $RESOURCENAME)
	            sleep 5
	            echo "$STATE"
	            #TODO: if can't disable it, find out why and exit
	        done
	        batchTools.sh queue delete $RESOURCENAME
	        while [ "$STATE" != "NO_SUCH_QUEUE" ]
	        do
	            STATE=$(batchTools.sh queue state $RESOURCENAME)
	            echo "$STATE"
	            sleep 5

	            #TODO: if can't delete it, find out why and exit
	        done

		else
			print_error "error: argument2 must be state, status, statusreason, disable, delete, disableAndDelete"
		fi

	elif [ "$ARGUMENT1" == "compute" ]; then
		if [ "$ARGUMENT2" == "state" ] || [ "$ARGUMENT2" == "status" ] || [ "$ARGUMENT2" == "statusreason" ]; then
			stateString=$(aws batch describe-compute-environments \
			--query 'computeEnvironments[*].[computeEnvironmentName,state,status,statusReason]' \
			| grep "$RESOURCENAME")
			state=$(echo "$stateString" | awk '{print $2}')
			status=$(echo "$stateString" | awk '{print $3}')
			statusreason=$(echo "$stateString" | awk '{print $4 $5 $6 $7}')
			if [ "$ARGUMENT2" == "state" ]; then
				if [ -z $state ]; then
					echo "NO_SUCH_COMPUTE_ENVIRONMENT"
				else
					echo "$state"
				fi
			fi
		elif [ "$ARGUMENT2" == "disable" ]; then
			aws batch update-compute-environment --compute-environment $RESOURCENAME --state DISABLED
		elif [ "$ARGUMENT2" == "delete" ]; then
			aws batch delete-compute-environment --compute-environment $RESOURCENAME
		elif [ "$ARGUMENT2" == "disableAndDelete" ]; then
			echo ""
			batchTools.sh compute disable $RESOURCENAME
			STATE=$(batchTools.sh compute state $RESOURCENAME)
			STATUS=$(batchTools.sh compute status $RESOURCENAME)
	        while [ "$STATUS" == "UPDATING" ]
	        do
	            sleep 5
	            STATE=$(batchTools.sh compute state $RESOURCENAME)
	            echo "$STATE"
	            #TODO: if can't disable it, find out why and exit
	        done
	        batchTools.sh compute delete $RESOURCENAME
	        STATE=$(batchTools.sh compute state $RESOURCENAME)
	        while [ "$STATE" != "NO_SUCH_COMPUTE_ENVIRONMENT" ]
	        do
	            STATE=$(batchTools.sh compute state $RESOURCENAME)
	            echo "$STATE"
	            sleep 5
	            #TODO: if can't delete it, find out why and exit
	        done
		else
			print_error "error: argument2 must be state, status, statusreason, disable, delete, disableAndDelete"
		fi
	else
		print_error "error: argument1 must be queue or compute"
	fi
else
	print_error "$# of arguments received. Expected three"
fi


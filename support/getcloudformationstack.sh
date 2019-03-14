#!/bin/bash

print_error(){
echo "Your command line contains $1 arguments"
echo "Usage:  
   getcloudformationstack.sh mystackname                      
	return values: stackexists, stackcreating, stackdoesnotexist
  getcloudformationstack.sh mystackname output
	return values: ALL outputs explicitely specified in cloudformation yaml"
echo"  getcloudformationstack.sh mystackname outputvaluename
	example outputvaluename arguments:  
		ecsTaskRole, spotFleetRole, ecsInstanceRole, lambdaBatchExecutionRole, awsBatchServiceRole
	return values: the id of the requested resource
	"
}
source ~/.batchawsdeploy/config
check_stack_exists(){
	#source ~/.batchawsdeploy/config
	STACKNAME=$1
	stackstatus=$(aws cloudformation describe-stacks \
	--query 'Stacks[*].[StackName,StackStatus]' \
	--output text | grep $STACKNAME | awk '{print $2}')

	if [ ! -z $stackstatus ]; then
    	if [ "$stackstatus" == "CREATE_COMPLETE" ]; then
    		echo "CREATE_COMPLETE"
		elif [ "$stackstatus" == "CREATE_IN_PROGRESS" ]; then
    		echo "CREATE_IN_PROGRESS"
    	else
			echo "---------------------------------------------------"
			echo "StackStatus: $stackstatus"
			getcloudformationstack.sh $STACKNAME events > ~/.batchawsdeploy/cloudformation_event_failure_log
			echo "---------------------------------------------------"
			getcloudformationstack.sh $STACKNAME failureevents
			echo "---------------------------------------------------"
    	fi
    else
    	echo "NO_SUCH_STACK"
    fi
}

# 1.) if one argument is provided check the status of the stack
if [ $# -gt 0 ]; then
	STACKNAME=$1
    #1.) if one argument, check if the stack exists
    if [ $# -eq 1 ]; then
    	check_stack_exists $STACKNAME
    fi
	#2.) if two arguments are provided, check the identity of the the 
	# specified service role for that stack
	if [ $# -eq 2 ]; then
		ARGUMENT=$2
		if [ "$ARGUMENT" == "output" ]; then
			aws cloudformation describe-stacks --stack-name $STACKNAME
		elif [ "$ARGUMENT" == "events" ]; then
			aws cloudformation describe-stack-events --stack-name $STACKNAME
		elif [ "$ARGUMENT" == "failureevents" ]; then
			aws cloudformation describe-stack-events --stack-name $STACKNAME \
			--query 'StackEvents[*].[ResourceStatus,ResourceStatusReason,StackName]' \
			| grep CREATE_FAILED \
			| grep -v "Resource creation cancelled"
		else
			ROLENAME=$ARGUMENT
			#replace newline with comma
			outputvalues=$(aws cloudformation describe-stacks \
			--stack-name $STACKNAME \
			--query 'Stacks[*].[Outputs[*]]' \
			| grep $ROLENAME | awk '{print $2}' | tr -s '\n' ',' )
			#remove trailing comma
			outputvalues=$(echo $outputvalues | sed 's/.$//')
			echo "$outputvalues"
		fi
	fi
else
	print_error $#
fi

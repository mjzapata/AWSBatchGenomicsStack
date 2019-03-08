#!/bin/bash

print_error(){
echo "Your command line contains $1 arguments"
echo "Usage:  
	getlcloudformationstack.sh mystackname                      
		return values: stackexists, stackcreating, stackdoesnotexist
	getlcloudformationstack.sh mystackname output
		return values: ALL outputs explicitely specified in cloudformation yaml"
echo"	getlcloudformationstack.sh mystackname outputvaluename
		example outputvaluename arguments:  
			ecsTaskRole, spotFleetRole, ecsInstanceRole, lambdaBatchExecutionRole, awsBatchServiceRole
		return values: the id of the requested resource
	"
}
check_stack_exists(){
	STACKNAME=$1
	stackstatus=$(aws cloudformation describe-stacks \
	--query 'Stacks[*].[StackName,StackStatus]' \
	--output text | grep $STACKNAME | awk '{print $2}')
	if [ ! -z $stackstatus ]; then
    	if [ "$stackstatus" == "CREATE_COMPLETE" ]; then
    		echo "stackexists"
		elif [ "$stackstatus" == "CREATE_IN_PROGRESS" ]; then
    		echo "stackcreating"
    	else
			echo "---------------------------------------------------"
			echo "StackStatus: $stackstatus"
			echo "other error, view cloudformation status here:"
			echo "https://console.aws.amazon.com/cloudformation/home"
			echo "---------------------------------------------------"
    	fi
    else
    	echo "stackdoesnotexist"
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
		ROLENAME=$2
		if [ "$ROLENAME" == "output" ]; then
			aws cloudformation describe-stacks --stack-name $STACKNAME
		else
			outputvalues=$(aws cloudformation describe-stacks \
			--stack-name $STACKNAME \
			--query 'Stacks[*].[Outputs[*]]' \
			| grep $ROLENAME | awk '{print $2}')
			echo $outputvalues
		fi
	fi
else
	print_error $#
fi

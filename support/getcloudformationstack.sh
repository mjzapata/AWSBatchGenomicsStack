#!/bin/bash

print_error(){
echo "Your command line contains $1 arguments"
echo "Usage:  
	getlcloudformationstack.sh mystackname                      
		return values: stackexists, stackcreating, stackdoesnotexist
	getlcloudformationstack.sh mystackname output
		return values: ALL outputs explicitely specified in cloudformation yaml
	getlcloudformationstack.sh mystackname outputvaluename
		example outputvaluename arguments:  ecsTaskRole, spotFleetRole, ecsInstanceRole, lambdaBatchExecutionRole, awsBatchServiceRole
		return values: the id of the requested resource
		"
}

check_stack_exists(){
	STACKNAME=$1
	runoutput=$(aws cloudformation describe-stacks --stack-name $STACKNAME 2>&1)
	stackexists=$(echo "$runoutput" | grep -c "does not exist")
	if [ $stackexists -eq 0 ]; then
    	stackcreatestatus=$(echo "$runoutput" | grep -c "CREATE_COMPLETE")
    	stackcreateinprogressstatus=$(echo "$runoutput" | grep -c "CREATE_IN_PROGRESS")
    	if [ $stackcreatestatus -eq 1 ]; then
    		echo "stackexists"
		elif [ $stackcreateinprogressstatus -eq 1 ]; then
    		echo "stackcreating"
    	else
    		echo "other error"
    		view
    	fi
    else
    	echo "stackdoesnotexist"
    fi
}

# 1.) if one argument is provided check the status of the stack
if [ $# -gt 0 ]; then
	STACKNAME=$1

	source ~/.batchawsdeploy/config
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE
    #check if the stack exists
    check_stack_exists $STACKNAME

#2.) if two arguments are provided, check the identity of the the specified service role for that stack
	if [ $# -eq 2 ]; then
		ROLENAME=$2
		if [ "$ROLENAME" == "output" ]; then
			aws cloudformation describe-stacks --stack-name $STACKNAME
		else
			outputline=$(aws cloudformation describe-stacks --stack-name $STACKNAME | grep $ROLENAME)
			IFS=$'\n'
			for line in $outputline
			do
				#echo line
				IFS=$'\t'
				tmp=($line)
				outputvalues="${tmp[2]}"
				echo $outputvalues
			done | paste -s -d, /dev/stdin

		fi
	fi
else
	print_error $#
fi

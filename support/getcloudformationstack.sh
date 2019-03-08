#!/bin/bash

#1 argument, check and see if stack named (command argument) exists, if not ask if you want to create it
# getlcloudformationstack.sh mystackname
#2 arguments
# getlcloudformationstack.sh mystackname 
	# options:  ecsTaskRole    spotFleetRole    ecsInstanceRole   lambdaBatchExecutionRole   awsBatchServiceRole
print_error(){
echo "Your command line contains $# arguments"
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

# 1.) if one argument is provided check the status of the stack
if [ $# -eq 1 ]; then
    STACKNAME=$1
    #check if the stack exists
    runoutput=$(aws cloudformation describe-stacks --stack-name $STACKNAME 2>&1 >/dev/null || true)
    #runoutput=$(aws cloudformation describe-stacks --stack-name $STACKNAME 1>&2 || true)
    echo $runoutput
    echo $runoutput
    stackexists=$(echo "$runoutput" | grep -c "does not exist")
    if [ $stackexists -eq 0 ]; then
    	stackcreatestatus=$(echo "$runoutput" | grep -c "CREATE_COMPLETE")
    	if [ $stackcreatestatus -eq 1 ]; then
    		echo "stackexists"
		else
    		echo "stackcreating"
    	fi
    else
    	echo "stackdoesnotexist"
    fi

#2.) if two arguments are provided, check the identity of the the specified service role for that stack
elif [ $# -eq 2 ]; then
	STACKNAME=$1
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
else
	print_error
fi


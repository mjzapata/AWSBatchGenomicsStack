#!/bin/bash

#1 argument, check and see if stack named (command argument) exists, if not ask if you want to create it
# getlcloudformationstack.sh mystackname
#2 arguments
# getlcloudformationstack.sh mystackname 
	# options:  ecsTaskRole    spotFleetRole    ecsInstanceRole   lambdaBatchExecutionRole   awsBatchServiceRole

# 1.) if one argument is provided check the status of the stack
if [ $# -eq 1 ]; then
    STACKNAME=$1
    #check if the stack exists
    runoutput=$(aws cloudformation describe-stacks --stack-name $STACKNAME 2>&1)
    stackexists=$(echo "$runoutput" | grep -c "does not exist")
    if [ $stackexists -eq 0 ]; then
    	#TODO: Check all of the roles necessary actually exist.
    	#the stack exists, now check if it's creation is complete
    	stackcreatestatus=$(echo "$runoutput" | grep -c "CREATE_COMPLETE")
    	if [ $stackcreatestatus -eq 1 ]; then
    		echo "stackexists"
		else
    		echo "Stack $STACKNAME still being created"
    		#CREATE_IN_PROGRESS
    	fi
    else
    	echo "Stack does not exist"
    fi

#2.) if two arguments are provided, check the identity of the the specified service role for that stack
elif [ $# -eq 2 ]; then
	STACKNAME=$1
	ROLENAME=$2

	#echo  "searching for" $STACKNAME $ROLENAME
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



		# roleline=$(aws cloudformation describe-stacks --stack-name $STACKNAME | grep $ROLENAME)

		# #when IFS (reserved variable) is a value other than default, tmp=($roleline)  gets parsed based on IFS
		# IFS=$'\t'
		# tmp=($roleline)
		# roleID="${tmp[2]}"
		# echo $roleID


	fi
else

	echo "Your command line contains $# arguments"
	echo "Usage:  getlcloudformationstack.sh mystackname                       #check if stack exists"
	echo "Usage:  getlcloudformationstack.sh mystackname output                #get all outputs"
	echo "Usage:  getlcloudformationstack.sh mystackname outputvaluename       #get value of specific output"
	echo "outputvaluename:  ecsTaskRole    spotFleetRole    ecsInstanceRole   lambdaBatchExecutionRole   awsBatchServiceRole"
	# if [ $# -lt 1 ]; then
	# 	echo "Your command line contains $# arguments"
	#     echo "Usage: \n  getlcloudformationstack.sh mystackname"
	#     echo "Usage: \n  getlcloudformationstack.sh mystackname servicerolename"
	
	# elif [ $# -gt 2 ]; then
	# 	echo "Your command line contains $# arguments"
	#     echo "Usage: \n  getlcloudformationstack.sh mystackname servicerolename"
	#     echo "Usage: \n  getlcloudformationstack.sh mystackname"
	# fi

fi


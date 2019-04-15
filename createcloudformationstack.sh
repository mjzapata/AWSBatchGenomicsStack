#!/bin/bash

#TODO: InternalAccessSecurityGroup

STACKNAME=$1
STACKFILE=$2
PARAMETERS=$3

if [ $# -gt 2 ]; then
	echo "Parameters:  $PARAMETERS"
	output=$(aws cloudformation create-stack \
	--template-body file://${STACKFILE} \
	--stack-name $STACKNAME \
	--capabilities CAPABILITY_IAM \
	--parameters $PARAMETERS)

	errorcode=$?
	if [ $errorcode != 0 ]; then
		echo "$output"
		echo "createcloudformation failed inside script, before submission: $errorcode"
		echo "CREATE_FAILED"
		exit $errorcode
	else
		echo "cloudformation submitted without error"
		echo "$output"
	fi

	echo "-----------------------------------------------------------------------------------------"
	echo "Creating cloudformation stack $STACKNAME. this could take a few minutes..."
	echo "https://console.aws.amazon.com/cloudformation/home"
	echo "-----------------------------------------------------------------------------------------"
	
	# wait loop to check for creating.  could take a few minutes
	# Then "Stack exists"
	stackstatus=$(getcloudformationstack.sh $STACKNAME)
	totaltime=0
	echo "|------------------------------------------------|"
	echo -n "<"
	while [ "$stackstatus" != "CREATE_COMPLETE" ]
	do
		stackstatus=$(getcloudformationstack.sh $STACKNAME) 
		echo -n "."
		sleep 5s
		totaltime=$((totaltime+5))
		#ROLLBACK_COMPLETE
		if [ "$stackstatus" != "CREATE_IN_PROGRESS" ]; then
			if [ "$stackstatus" != "CREATE_COMPLETE" ]; then
				echo ""
				echo "stackstatus=$stackstatus"
				echo ""

				#echo "infrastructureScriptStatus=FAILURE"
				exit 1
			fi
		fi
	done
	echo ">"
	echo "Stack $STACKNAME created in $totaltime seconds"

else
	echo "Usage: createcloudformation.sh [mystackname] delete  delete given stack (may take some time)"
	echo "Usage: createcloudformation.sh [mystackname] [mystackfile] (will take several minutes to create all resources)"
	echo "Usage: createcloudformation.sh [mystackname] [mystackfile] --parameters [additional parameterstring]"
	echo -n "example: createcloudformation.sh [mystackname] [mystackfile] "
	echo "\"--parameters ParameterKey="NetworkAccessIP",ParameterValue="my.ip.add.ress/32\" ""
	echo "(possible parameters must be specified in cloudformation template ahead of time in the parameters section)"
	echo "the cloudformation stack included here allows for ssh only from the specified IP address ranges following CIDR notation"
fi


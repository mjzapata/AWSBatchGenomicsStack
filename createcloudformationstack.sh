#!/bin/bash

if [ $# -eq 2 ]; then

	STACKNAME=$1
	STACKFILE=$2

	#if the second argument is delete instead of anything else, delete this stack
	if [ $STACKFILE == "delete" ]; then
		aws cloudformation delete-stack --stack-name $STACKNAME
		echo "Stack $STACKNAME deleted"
	else
		output=$(aws cloudformation create-stack \
		--template-body file://${STACKFILE} \
		--stack-name $STACKNAME \
		--capabilities CAPABILITY_IAM)

		echo "Creating cloudformation stack $STACKNAME. this could take a few minutes..."
		# wait loop to check for creating.  could take a few minutes
		# Then "Stack exists"
		stackstatus=$(./getcloudformationstack.sh $STACKNAME)
		totaltime=0
		while [ "$stackstatus" != "Stack exists" ]
		do
			stackstatus=$(./getcloudformationstack.sh $STACKNAME) 
			echo "."
			sleep 10s
			totaltime=$((totaltime+10))
		done
		echo " Stack $STACKNAME created in $totaltime seconds"

	fi

elif [[ $# -gt 2 ]]; then
		STACKNAME=$1
		STACKFILE=$2
		PARAMETERS=$3
		echo "Parameters:  $PARAMETERS"
		output=$(aws cloudformation create-stack \
		--template-body file://${STACKFILE} \
		--stack-name $STACKNAME \
		--capabilities CAPABILITY_IAM \
		--parameters $PARAMETERS)

		echo "Creating cloudformation stack $STACKNAME. this could take a few minutes..."
		# wait loop to check for creating.  could take a few minutes
		# Then "Stack exists"
		stackstatus=$(./getcloudformationstack.sh $STACKNAME)
		totaltime=0
		echo "|-------------------------------|"
		echo -n "<"
		while [ "$stackstatus" != "Stack exists" ]
		do
			stackstatus=$(./getcloudformationstack.sh $STACKNAME) 
			echo -n "."
			sleep 5s
			totaltime=$((totaltime+5))
		done
		echo ">"
		echo "Stack $STACKNAME created in $totaltime seconds"


		#TODO: make another elif for a parameter file instead

else
	echo "Usage: ./createcloudformation.sh [mystackname] delete  delete given stack (may take some time)"
	echo "Usage: ./createcloudformation.sh [mystackname] [mystackfile] (will take several minutes to create all resources)"
	echo "Usage: ./createcloudformation.sh [mystackname] [mystackfile] --parameters [additional parameterstring]"
	echo "example: ./createcloudformation.sh [mystackname] [mystackfile] \"--parameters ParameterKey="NetworkAccessIP",ParameterValue="my.ip.add.ress/32\" "     (possible parameters must be specified in cloudformation template ahead of time in the parameters section)"
	echo "the cloudformation stack included here allows for ssh only from the specified IP address ranges following CIDR notation"
fi

#aws --region us-east-1 cloudformation create-stack --stack-name stackBLJ --template-body file://Managed_EC2_and_Spot_Batch_Environment.json --capabilities CAPABILITY_IAM

#InternalAccessSecurityGroup
#aws cloudformation create-stack \
#		--template-body file://${STACKFILE} \
#		--stack-name $STACKNAME \
#		--capabilities CAPABILITY_IAM \
#		--parameters ParameterKey="NetworkAccessIP",ParameterValue="173.92.84.208/32"

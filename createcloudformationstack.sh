#!/bin/bash


#aws --region us-east-1 cloudformation create-stack --stack-name stackBLJ 
		#--template-body file://Managed_EC2_and_Spot_Batch_Environment.json --capabilities CAPABILITY_IAM

#InternalAccessSecurityGroup
#aws cloudformation create-stack \
#		--template-body file://${STACKFILE} \
#		--stack-name $STACKNAME \
#		--capabilities CAPABILITY_IAM \
#		--parameters ParameterKey="NetworkAccessIP",ParameterValue="173.92.84.208/32"
STACKNAME=$1
STACKFILE=$2
PARAMETERS=$3

if [ $# -eq 2 ]; then
	#if the second argument is delete instead of anything else, delete this stack
	if [ $STACKFILE == "delete" ]; then
		aws cloudformation delete-stack --stack-name $STACKNAME
		echo "Stack $STACKNAME deleted"
	else

		output=$(aws cloudformation create-stack \
		--template-body file://${STACKFILE} \
		--stack-name $STACKNAME \
		--capabilities CAPABILITY_IAM)

		echo "-----------------------------------------------------------------------------------------"
		echo "Creating cloudformation stack $STACKNAME. this could take a few minutes..."
		echo "https://console.aws.amazon.com/cloudformation/home"
		echo "-----------------------------------------------------------------------------------------"
		# wait loop to check for creating.  could take a few minutes
		# Then "Stack exists"
		stackstatus=$(getcloudformationstack.sh $STACKNAME)
		totaltime=0
		while [ "$stackstatus" != "stackexists" ]
		do
			stackstatus=$(getcloudformationstack.sh $STACKNAME) 
			echo "."
			sleep 10s
			totaltime=$((totaltime+10))
		done
		echo " Stack $STACKNAME created in $totaltime seconds"

	fi

elif [[ $# -gt 2 ]]; then

		echo "Parameters:  $PARAMETERS"
		output=$(aws cloudformation create-stack \
		--template-body file://${STACKFILE} \
		--stack-name $STACKNAME \
		--capabilities CAPABILITY_IAM \
		--parameters $PARAMETERS)

		echo "-----------------------------------------------------------------------------------------"
		echo "Creating cloudformation stack $STACKNAME. this could take a few minutes..."
		echo "https://console.aws.amazon.com/cloudformation/home"
		echo "-----------------------------------------------------------------------------------------"
		# wait loop to check for creating.  could take a few minutes
		# Then "Stack exists"
		stackstatus=$(getcloudformationstack.sh $STACKNAME)
		totaltime=0
		echo "|------------------------------------------|"
		echo -n "<"
		while [ "$stackstatus" != "stackexists" ]
		do
			stackstatus=$(getcloudformationstack.sh $STACKNAME) 
			echo -n "."
			sleep 5s
			totaltime=$((totaltime+5))
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


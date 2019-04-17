#!/bin/bash

# this script launches a head node for submitting batch jobs to AWS
# use same cloud-init
# only launchable after compute environment is setup?
# set e-mail notifications

#TODO:
# script to enable the head node to be accessed from only select IPs
# run the script once from a new IP
# seperate instance for displaying data or just a seperate docker image?
# seperate port for management console?
print_error(){
echo "This script is for launching an EC2 node, usually a head node or bastion node."
echo "Usage: "
echo "  EC2Node.sh property [STACKNAME] listallinstancesinstack"
echo "  EC2Node.sh property [STACKNAME] listallrunninginstancesinstack"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] exist"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] instanceHostNamePublic"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] instanceHostNamePublic"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] instanceHostNamePublic"
echo "  EC2Node.sh directconnect [STACKNAME] [INSTANCENAME] [INSTANCETYPE]"
echo "  EC2Node.sh runscript_attached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
echo "  EC2Node.sh runscript_detached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
echo "  EC2Node.sh terminate [STACKNAME] [INSTANCENAME]"
echo "  EC2Node.sh terminate [STACKNAME] allinstances"
}

if [ $# -gt 2 ]; then
	EC2RUNARGUMENT=$1
	STACKNAME=$2
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	if [ -f $BATCHAWSCONFIGFILE ]; then
		source $BATCHAWSCONFIGFILE
	fi
	INSTANCENAME=$3
	ARG4=$4
	ARG5=$5

#check for existence of HEAD Node
if [ "$EC2RUNARGUMENT" == "property" ]; then
	PROPERTYNAME=$ARG4
	#NOTE: Only allow one Node of type head node
	#HEADNODENAME="HeadNode"
	#if -v
		#ls ~/.batchawsdeploy/instance_${STACKNAME}_${HEADNODENAME}*
	# https://stackoverflow.com/questions/6363441/check-if-a-file-exists-with-wildcard-in-shell-script

	# awscli, prvent newline in query: https://github.com/aws/aws-cli/issues/758 
	instanceProperties=$(aws ec2 describe-instances \
		--filters Name=tag:StackName,Values="$STACKNAME" \
		--query "Reservations[].Instances[].[ Tags[?Key=='Name'].Value | [0], Tags[?Key=='StackName'].Value | [0], InstanceId, State.Name, Placement.AvailabilityZone, PublicDnsName, PublicIpAddress, NetworkInterfaces[*].PrivateIpAddress | [0], PrivateDnsName]")

	runningInstances=$(echo "$instanceProperties" | grep "running")

	if [ "$INSTANCENAME" == "listallrunninginstancesinstack" ]; then
		echo "$runningInstances"
	elif [ "$INSTANCENAME" == "listallinstancesinstack" ]; then
		echo "$instanceProperties"
	else
		instanceHostNamePublic=$(getinstance.sh $instanceID PublicDnsName)
    fi


	if [ "$PROPERTYNAME" == "exist" ]; then
		instanceID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="$INSTANCENAME",Name=tag:StackName,Values="$STACKNAME" --query "Reservations[].Instances[].InstanceId")
		instanceState=$(aws ec2 describe-instances --filters Name=tag:Name,Values="$INSTANCENAME",Name=tag:StackName,Values="$STACKNAME" --query "Reservations[].Instances[].State.Name")
    	if [[ $instanceState == *"running"* ]]; then
    		#echo "running"
    		#echo "instance_up"
    		#echo "connecting to the instance"
    		#echo "check for ingress"

    		#aws ec2 describe-instances --filters Name=tag:StackName,Values="$STACKNAME" --query "Reservations[].Instances[].InstanceId"
			#instanceProps=$(aws ec2 describe-instances --filters Name=tag:StackName,Values="$STACKNAME")
			#instanceID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="${INSTANCENAME}", --query "Reservations[].Instances[].InstanceId")
			instanceID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="${INSTANCENAME}",Name=tag:StackName,Values="$STACKNAME",Name=instance-state-name,Values=running --query "Reservations[].Instances[].InstanceId")
			echo "$instanceID"

    	else
    		echo "instance_down"
    	fi
	fi

elif [ $# -eq 3 ] && [ "$EC2RUNARGUMENT" == "terminate" ]; then
	
	# instanceProperties=$(aws ec2 describe-instances \
	#     	--query "Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, Name, InstanceId]" \
	#     	--output text | grep ${REGION} | grep running | grep ${instanceID}) # | awk '{print $2}')


	if [ "$INSTANCENAME" == "allinstances" ]; then
		instanceIDs=$(aws ec2 describe-instances \
		--filters Name=tag:StackName,Values="$STACKNAME" \
		--query "Reservations[].Instances[].InstanceId")
		echo "terminating instanceIDs:  $instanceIDs"
		aws ec2 terminate-instances --instance-ids $instanceIDs
	else
		instanceID=$(aws ec2 describe-instances \
		--filters Name=tag:Name,Values="$INSTANCENAME" Name=tag:StackName,Values="$STACKNAME" \
		--query "Reservations[].Instances[].InstanceId")

		echo "terminating instanceName: $INSTANCENAME,  instanceID: $instanceID"
		aws ec2 terminate-instances --instance-ids $instanceID
	fi

#directconnect
elif [ $# -eq 4 ] && [ "$EC2RUNARGUMENT" == "directconnect" ]; then
	#SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
	INSTANCETYPE=$ARG4
	SCRIPTNAME=$ARG5

	SECURITYGROUPS="$BASTIONSECURITYGROUP"
	echo "STACKNAME=$STACKNAME"
	echo "INSTANCETYPE=$INSTANCETYPE"
	echo "SECURITYGROUPS=$SECURITYGROUPS"
	echo "IMAGEID=$IMAGEID"
	echo "HEADNODELAUNCHTEMPLATEID=$HEADNODELAUNCHTEMPLATEID"
	instanceID=$(EC2Node.sh property $STACKNAME $INSTANCENAME exist)

	if [ "$instanceID" == "instance_down" ]; then
		launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT
	else
		#TODO: consolidate with code below
		echo ""
		echo "instance with Name: $INSTANCENAME already running"
		echo "instanceID=$instanceID"

		SSH_OPTIONS="-o IdentitiesOnly=yes"
		instanceHostNamePublic=$(getinstance.sh $instanceID PublicDnsName)
		echo "to reconnect to this instance, run: "
		echo "   ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS"
		echo ""

	fi

# runscript_attached or runscript_attached
elif [ $# -eq 5 ]; then
	if [ "$EC2RUNARGUMENT" == "runscript_detached" ] || [ "$EC2RUNARGUMENT" == "runscript_attached" ]; then
		INSTANCETYPE=$ARG4
		SCRIPTNAME=$ARG5

		#LAUNCH HEAD NODE WITH SCRIPT
		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		echo "SECURITYGROUPS=$SECURITYGROUPS"

		launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $SCRIPTNAME


		instanceID=$(EC2Node.sh property $STACKNAME $INSTANCENAME exist)
		echo ""
		echo "instance with Name: $INSTANCENAME already running"
		echo "instanceID=$instanceID"

		SSH_OPTIONS="-o IdentitiesOnly=yes"
		instanceHostNamePublic=$(getinstance.sh $instanceID PublicDnsName)
		echo "to reconnect to this instance, run: "
		echo "   ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS"
		echo ""

	elif [ "$EC2RUNARGUMENT" == "createAMI" ]; then

		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		echo "SECURITYGROUPS=$SECURITYGROUPS"

		launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $SCRIPTNAME


	else
		print_error
	fi

else
	print_error
fi

else
	print_error
fi

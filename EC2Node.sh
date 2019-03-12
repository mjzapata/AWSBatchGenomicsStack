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
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] exist"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] instanceHostNamePublic"
echo "  EC2Node.sh property [STACKNAME] [INSTANCENAME] instanceHostNamePublic"
echo "  EC2Node.sh directconnect [STACKNAME] [INSTANCENAME] [INSTANCETYPE]"
echo "  EC2Node.sh runscript_attached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
echo "  EC2Node.sh runscript_detached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
}

if [ $# -gt 2 ]; then
	EC2RUNARGUMENT=$1
	STACKNAME=$2
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE
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

	for f in ~/.batchawsdeploy/instance_${STACKNAME}_${INSTANCENAME}*; do
		#[ -e "$f" ] && echo "HeadNode Instance File found" || echo "No HeadNode descriptor file found"
	    [ -e "$f" ]
	    	#check if the instance is still running
	    	# https://stackoverflow.com/a/6119010
	    	source $f
	    	#echo $instanceID
	    	instanceProperties=$(aws ec2 describe-instances \
	    	--query "Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, Name, InstanceId]" \
	    	--output text | grep ${REGION} | grep running | grep ${instanceID}) # | awk '{print $2}')

			if [ "$PROPERTYNAME" == "exist" ]; then
				instanceState=$(getinstance.sh $instanceID State.Name)
		    	if [ "$instanceState" == "running" ]; then
		    		echo "running"
		    		#echo "instance_up"
		    		#echo "connecting to the instance"
		    		#echo "check for ingress"
		    	else
		    		echo "instance_down"
		    	fi
	    	fi


	    break
	done

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

	launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
	$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT

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
	else
		print_error
	fi

else
	print_error
fi

else
	print_error
fi

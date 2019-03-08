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
echo "Usage: "
echo " launchEC2HeadNode.sh exist [STACKNAME] [INSTANCENAME]"
echo " launchEC2HeadNode.sh directconnect [STACKNAME] [INSTANCENAME] [INSTANCETYPE]"
echo " launchEC2HeadNode.sh runscript_attached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
echo " launchEC2HeadNode.sh runscript_detached [STACKNAME] [INSTANCENAME] [INSTANCETYPE] startHeadNodeGui.sh"
}

if [ $# -gt 2 ]; then
	EC2RUNARGUMENT=$1
	STACKNAME=$2
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE
	INSTANCENAME=$3
	INSTANCETYPE=$4
	SCRIPTNAME=$5
else
	print_error
fi

#check for existence of HEAD Node
if [ "$EC2RUNARGUMENT" == "exist" ]; then
	#NOTE: Only allow one Node of type head node
	HEADNODENAME="HeadNode"
	ls ~/.batchawsdeploy/instance_${STACKNAME}_${HEADNODENAME}*
	# https://stackoverflow.com/questions/6363441/check-if-a-file-exists-with-wildcard-in-shell-script
	for f in ~/.batchawsdeploy/instance_${STACKNAME}_${HEADNODENAME}*; do
	    [ -e "$f" ] && echo "HeadNode Instance File found" || echo "No HeadNode descriptor file found"
	    	#check if the instance is still running
	    	# https://stackoverflow.com/a/6119010
	    	source $f
	    	instanceState=$(aws ec2 describe-instances \
	    	--query "Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, Name, InstanceId]" \
	    	--output text | grep ${REGION} | grep running ) #| grep ${instanceID} | awk '{print $2}')
	    	
	    	echo "instanceState=$instanceState"
	    	
	    	if [ "$instanceState" == "running" ]; then
	    		echo "instance running"
	    		echo "should connect to the instance"
	    		echo "check for ingress"


	    	else
	    		echo "instance is not running"


	    	fi
			#ping -oc 100000 $instanceHostNamePublic > /dev/null && say "up" || say "down"
			#ping -oc 100000 1.1.1.112 > /dev/null && say "up" || say "down"

	    break
	done

#directconnect
elif [ $# -eq 4 ] && [ "$EC2RUNARGUMENT" == "directconnect" ]; then
	#SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
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

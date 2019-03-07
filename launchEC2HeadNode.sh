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
	echo "launchEC2HeadNode.sh directconnect [STACKNAME] [INSTANCETYPE]"
	echo "launchEC2HeadNode.sh runscript_attached [STACKNAME] [INSTANCETYPE] startHeadNodeGui.sh"
	echo "launchEC2HeadNode.sh runscript_detached [STACKNAME] [INSTANCETYPE] startHeadNodeGui.sh"
}
if [ $# -gt 2 ]; then
	EC2RUNARGUMENT=$1
	STACKNAME=$2

	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE
	INSTANCETYPE=$3
	SCRIPTNAME=$4

else
	print_error
fi

#directconnect
if [ $# -eq 3 ] && [ "$EC2RUNARGUMENT" == "directconnect" ]; then
	#TODO: might have to make more permissions to allow EFS mounting between security groups
	#SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
	SECURITYGROUPS="$BASTIONSECURITYGROUP"

	echo "STACKNAME=$STACKNAME"
	echo "INSTANCETYPE=$INSTANCETYPE"
	echo "SECURITYGROUPS=$SECURITYGROUPS"
	echo "IMAGEID=$IMAGEID"
	INSTANCENAME="HeadNode"
	echo "HEADNODELAUNCHTEMPLATEID=$HEADNODELAUNCHTEMPLATEID"

	launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
	$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT

# runscript_attached or runscript_attached
elif [ $# -eq 4 ];
	if [ "$EC2RUNARGUMENT" == "runscript_detached" ] || [ "$EC2RUNARGUMENT" == "runscript_attached" ]; then

		#LAUNCH HEAD NODE WITH SCRIPT
		#launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		# $AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS \
		# $EC2RUNARGUMENT startHeadNode.sh 
		INSTANCENAME="HeadNode"

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

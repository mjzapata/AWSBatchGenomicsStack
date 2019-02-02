#!/bin/bash

#this script launches a head node for submitting batch jobs to AWS

# use same cloud-init
# only launchable after compute environment is setup?
# set e-mail notifications

#TODO:
# script to enable the head node to be accessed from only select IPs
# run the script once from a new IP
# seperate instance for displaying data or just a seperate docker image?
# seperate port for management console?


EC2RUNARGUMENT=$1
STACKNAME=$2
INSTANCETYPE=$3
SCRIPTNAME=$4

if [ $# -eq 3 ]; then
	
	#directconnect
	if [ "$EC2RUNARGUMENT" == "directconnect" ]; then

		AWSCONFIGFILENAME=~/.aws/${STACKNAME}.sh
		source $AWSCONFIGFILENAME

		#TODO: might have to make more permissions to allow EFS mounting between security groups
		#SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		SECURITYGROUPS="$BASTIONSECURITYGROUP"

		echo "STACKNAME=$STACKNAME"
		echo "INSTANCETYPE=$INSTANCETYPE"
		echo "SECURITYGROUPS=$SECURITYGROUPS"
		echo "IMAGEID=$IMAGEID"

		INSTANCENAME="HeadNode"

		#MYPUBLICIPADDRESS
		echo "HEADNODELAUNCHTEMPLATEID=$HEADNODELAUNCHTEMPLATEID"
		# AMIIDENTIFIER=null
		# IMAGETAG=null
		# IMAGETAGVALUE=null

		./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $HEADNODELAUNCHTEMPLATEID $AWSCONFIGFILENAME

	fi

elif [ $# -eq 4 ]; then

	if [ "$EC2RUNARGUMENT" == "runscript" ]; then
		#LAUNCH HEAD NODE WITH SCRIPT
		#./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		# $AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS \
		# $EC2RUNARGUMENT startHeadNode.sh 
		
		INSTANCENAME="HeadNode"
		#INSTANCETYPE=t2.micro
		#IMAGEID=ami-05422e32bf76f947c

		
		AWSCONFIGFILENAME=~/.aws/${STACKNAME}.sh
		source $AWSCONFIGFILENAME

		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		echo "SECURITYGROUPS=$SECURITYGROUPS"


		./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $HEADNODELAUNCHTEMPLATEID $AWSCONFIGFILENAME $SCRIPTNAME
	fi

else
	echo "Usage: "
	echo "./launchEC2HeadNode.sh directconnect [STACKNAME] [INSTANCETYPE]"
	echo "./launchEC2HeadNode.sh runscript [STACKNAME] [INSTANCETYPE] startHeadNode.sh"

fi

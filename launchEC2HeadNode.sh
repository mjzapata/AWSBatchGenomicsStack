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
	#if [ "$ARGUMENT" == "create" ]; then

		#INSTANCETYPE=t2.micro
		#imageID=ami-05422e32bf76f947c
		#EBSVOLUMESIZEGB=0

		echo "STACKNAME=$STACKNAME"
		echo "INSTANCETYPE=$INSTANCETYPE"

		AWSCONFIGFILENAME=~/.aws/${STACKNAME}.sh
		source $AWSCONFIGFILENAME

		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		echo "SECURITYGROUPS=$SECURITYGROUPS"

		INSTANCENAME="HeadNode"

		#MYPUBLICIPADDRESS

		#LAUNCHTEMPLATEID=lt-01473bb551ec95911

		# AMIIDENTIFIER=null
		# IMAGETAG=null
		# IMAGETAGVALUE=null
		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"

		./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID $AWSCONFIGFILENAME

		#scp ~/.aws/${STACKNAME}.sh          ec2-user
		#scp ~/.aws/BLJStack52KeyPair.pem
		#scp BLJStack52JobDefinitions.tsv
		#scp ~/.nextflow/nextflow.config     ec2-user
		#scp ~/.aws/config
		#scp ~/.aws/credentials
	fi

elif [ $# -eq 4 ]; then

	if [ "$EC2RUNARGUMENT" == "runscript" ]; then
		#LAUNCH HEAD NODE WITH SCRIPT
		#./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB $AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS $EC2RUNARGUMENT startHeadNode.sh 
		
		INSTANCENAME="HeadNode"
		#INSTANCETYPE=t2.micro
		#IMAGEID=ami-05422e32bf76f947c
		#EBSVOLUMESIZEGB=0

		
		AWSCONFIGFILENAME=~/.aws/${STACKNAME}.sh
		source $AWSCONFIGFILENAME
		
		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"
		echo "SECURITYGROUPS=$SECURITYGROUPS"


		./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB \
		$SUBNETS $SECURITYGROUPS $INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID $AWSCONFIGFILENAME $SCRIPTNAME
	fi

else
	echo "Usage: "
	echo "./launcheEC2HeadNode.sh directconnect [STACKNAME] [INSTANCETYPE]"
	echo "./launcheEC2HeadNode.sh runscript [STACKNAME] [INSTANCETYPE] startHeadNode.sh"

fi

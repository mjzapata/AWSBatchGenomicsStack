#!/bin/bash

#aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-xxxxxxxx --subnet-id subnet-xxxxxxxx

# Use this template image to create the BLJ image with more EBS memory

if [ $# -eq 12 ]; then

	# TEMPLATEIMAGEID=ami-0b9a214f40c38d5eb  #as of 2018oct17
	# INSTANCETYPE=t2.micro
	# KEYNAME=BioLockJKeyPairAMI
	# EBSVOLUMESIZEGB="50"
	# AMIIDENTIFIER=generic

	# STACKNAME=tempbljsubnetstack2
	# STACKFILE=BLJStack.json

	# IMAGETAG=ImageRole
	# IMAGETAGVALUE=BLJManager

	STACKNAME=$1
	TEMPLATEIMAGEID=$2
	INSTANCETYPE=$3
	KEYNAME=$4
	EBSVOLUMESIZEGB=$5
	AMIIDENTIFIER=$6
	STACKFILE=$7
	IMAGETAG=$8
	IMAGETAGVALUE=$9
	SUBNETS=${10}
	BASTIONSECURITYGROUP=${11}
	MYPUBLICIPADDRESS=${12}

	#run EC2 instances: https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
	# https://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-launch.html
	EC2RunOutput=$(aws ec2 run-instances \
		--image-id $TEMPLATEIMAGEID \
		--count 1 \
		--instance-type $INSTANCETYPE \
		--key-name $KEYNAME \
		--subnet-id $SUBNETS \
		--block-device-mappings 'DeviceName=/dev/sdb,Ebs={VolumeSize="'$EBSVOLUMESIZEGB'",DeleteOnTermination=true,Encrypted=true,VolumeType=gp2}' )
	echo $EC2RunOutput

	#status
	IFS=$'\t'
	vars=$(echo $EC2RunOutput | grep INSTANCES)
	# instanceID 8th column i-00f88ef1c7ca1820e
	instanceID=$(echo $vars  | awk '//{print $7}')
	echo $instanceID

	#get instance status and wait for it to run
	# RUNNING or ???  TERMINATED  (actually returns nothing) second row third column
	instancestatus=$(./getinstance.sh $instanceID status)
	instancetime=0
	echo "Starting EC2 instance. This may take a minute"
	while [ "$instancestatus" != "running" ]
	do
		instancestatus=$(./getinstance.sh $instanceID status) 
		echo "."
		sleep 10s
		instancetime=$((instancetime+10))
	done
	echo " Instance:  $instanceID  created in $instancetime seconds"

	# get IP address, and hostname (#TODO, get public hostname)
	instanceIP=$(./getinstance.sh $instanceID ipaddress)
	instanceHostName=$(./getinstance.sh $instanceID hostname)

	#join the instance to the right security group, 
	aws ec2 modify-instance-attribute --instance-id $instanceID --groups $BASTIONSECURITYGROUP
	# authorize ingress on that port
	# aws ec2 authorize-security-group-ingress --group-id sg-097f9d3eb0af8a053 --protocol tcp --port 22 --cidr 173.92.84.208/32

	#6.) SSH into the host and run the configure script then close it and create an AMI based on this image
	# ssh trick to not check host keyfile https://linuxcommando.blogspot.com/2008/10/how-to-disable-ssh-host-key-checking.html
	# run local script on remote host with ssh: https://stackoverflow.com/questions/305035/how-to-use-ssh-to-run-a-shell-script-on-a-remote-machine 
	ssh -o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		-i ${KEYNAME}.pem ec2-user@${instanceIP} \
		'bash -s' < configureEC2forAMI.sh
	echo "----------------------------------------"
	echo "----------------------------------------"
	echo "Check for any errors in the AMI creation"

	#run it with the script configureEC2forAMI.sh   https://stackoverflow.com/questions/305035/how-to-use-ssh-to-run-a-shell-script-on-a-remote-machine 
	imageID=$(aws ec2 create-image --instance-id $instanceID --name BLJAMI${AMIIDENTIFIER}-${EBSVOLUMESIZEGB}GB_DOCKER)  #--description enter a description
	imageStatus=$(./getec2images.sh $imageID status)
	echo "creating AMI. This may take a minute"
	imagetime=0
	while [ "$imageStatus" != "available" ]
	do
		imageStatus=$(./getec2images.sh $imageID status)
		echo "."
		sleep 5s
		imagetime=$((imagetime+5))
	done
	echo " Instance:  $imageID  created in $imagetime seconds"


	#TAG the image as defined by the two tag values (used for filtering if this image was already created)
	aws ec2 create-tags --resources $imageID --tags Key=$IMAGETAG,Value=$IMAGETAGVALUE
	echo $imageID

	# CREATE volume?  Not necessary if specified in the ami
	# aws ec2 attach-volume --volume-id vol-1234567890abcdef0 --instance-id i-01474ef662b89480 --device /dev/sdf

	# 4.) shutdown
	#TODO: Dry run,
	aws ec2 terminate-instances --instance-ids $instanceID


	#TODO: maybe don't need to do this....
	# 6.) Cleanup, delete stack and key
	#./awskeypair.sh delete $KEYNAME
	#./createcloudformationstack.sh $STACKNAME "delete"


else
	echo "Usage: ./createAMI.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPEFORAMICREATION $KEYNAME $EBSVOLUMESIZEGB $AMIIDENTIFIER $STACKFILE $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS"
fi

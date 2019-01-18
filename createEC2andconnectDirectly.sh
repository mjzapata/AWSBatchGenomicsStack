#!/bin/bash

STACKNAME=$1
TEMPLATEIMAGEID=$2
INSTANCETYPE=$3
KEYNAME=$4
SUBNETS=$5
BASTIONSECURITYGROUP=$6
ARGUMENT=$7

#TODO: Check if instance with tag is already running

EC2RunOutput=$(aws ec2 run-instances \
		--image-id $TEMPLATEIMAGEID \
		--count 1 \
		--instance-type $INSTANCETYPE \
		--key-name $KEYNAME \
		--subnet-id $SUBNETS)
	echo $EC2RunOutput

	#status
	IFS=$'\t'
	vars=$(echo $EC2RunOutput | grep INSTANCES)
	# instanceID 8th column i-00f88ef1c7ca1820e
	instanceID=$(echo $vars  | awk '//{print $7}')
	echo ""
	echo "instanceID: $instanceID"
	echo ""

	# #get instance status and wait for it to run
	# # RUNNING or ???  TERMINATED  (actually returns nothing) second row third column
	# instancereachability=$(./getinstance.sh $instanceID reachability)
	# instancetime=0
	# echo "Starting EC2 instance. This may take a minute"
	# echo "|---------------------------------|"
	# echo -n "<"
	# while [ "$instancereachability" != *"passed"* ]
	# do
	# 	instancereachability=$(./getinstance.sh $instanceID reachability) 
	# 	echo -n "."
	# 	sleep 5s
	# 	instancetime=$((instancetime+5))
	# done
	# echo ".>"
	# echo " Instance:  $instanceID  created in $instancetime seconds"


	# get IP address, and hostname (#TODO, get public hostname)
	instanceIP=$(./getinstance.sh $instanceID ipaddress)
	echo "instanceIP $instanceIP"
	instanceHostName=$(./getinstance.sh $instanceID hostname)
	echo "instanceHostName: $instanceHostName"

	aws ec2 wait instance-running --instance-ids $instanceID

	#join the instance to the right security group, 
	aws ec2 modify-instance-attribute --instance-id $instanceID --groups $BASTIONSECURITYGROUP
	# authorize ingress on that port
	# aws ec2 authorize-security-group-ingress --group-id sg-097f9d3eb0af8a053 --protocol tcp --port 22 --cidr 173.92.84.208/32
if [[ $ARGUMENT == "directconnect" ]]; then
	#6.) SSH into the host and run the configure script then close it and create an AMI based on this image
	# ssh trick to not check host keyfile https://linuxcommando.blogspot.com/2008/10/how-to-disable-ssh-host-key-checking.html
	# run local script on remote host with ssh: https://stackoverflow.com/questions/305035/how-to-use-ssh-to-run-a-shell-script-on-a-remote-machine 
	ssh -o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		-i ${KEYNAME}.pem ec2-user@${instanceIP}


# elif [[ ARGUMENT == "runscript" ]]; then
# 	ssh -o UserKnownHostsFile=/dev/null \
# 		-o StrictHostKeyChecking=no \
# 		-i ${KEYNAME}.pem ec2-user@${instanceIP} \
# 		'bash -s' < fstabAMI.sh
else
	echo "Usage: ./createEC2andconnectDirectly.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPE $KEYNAME $SUBNETS ARGUMENT"

fi



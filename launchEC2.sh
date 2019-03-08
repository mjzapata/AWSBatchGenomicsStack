#!/bin/bash
# Argument 14 is an overload argument. WATCH OUT.

#TODO: Massively simplify this
MIN_NUM_ARGUMENTS_EXPECTED=10

print_help() {
	echo -n "Usage: launchEC2.sh STACKNAME IMAGEID INSTANCETYPE KEYNAME EBSVOLUMESIZEGB"
	echo	"SUBNETS SECURITYGROUPS INSTANCENAME EC2RUNARGUMENT HEADNODELAUNCHTEMPLATEID"
	"minimum number of arguments expected: $MIN_NUM_ARGUMENTS_EXPECTED"
}

#if [ "$EC2RUNARGUMENT" == "delete" ]
#fi

if [ $# -gt 8 ]; then

	STACKNAME=$1
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE
	echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE"
	echo "BATCHAWSDEPLOY_HOME=$BATCHAWSDEPLOY_HOME"

	TEMPLATEIMAGEID=$2
	INSTANCETYPE=$3
	KEYNAME=$4
	EBSVOLUMESIZEGB=$5
	SUBNETS=$6
	SECURITYGROUPS=$7
	INSTANCENAME=$8
	LAUNCHTEMPLATEID=$HEADNODELAUNCHTEMPLATEID
	EC2RUNARGUMENT=$9
	#LAUNCHTEMPLATEID=${10}
	SCRIPTNAME=${10}

	AMIIDENTIFIER=${11}
	IMAGETAG=${12}
	IMAGETAGVALUE=${13}

	# check if script is NOT in this directory
	# set Scriptname to full path
	if [ -f "${SCRIPTNAME}" ]; then
		SCRIPTPATH=$SCRIPTNAME
	else
		SCRIPTPATH=${BATCHAWSDEPLOY_HOME}${SCRIPTNAME}
	fi

	#replace comma of Security groups with spaces
	SECURITYGROUPS=`echo "$SECURITYGROUPS" | tr ',' ' '`
	echo "SECURITYGROUPS=$SECURITYGROUPS"

	#TODO: more elegant way of choosing subnet
	SUBNET=$(echo "$SUBNETS" | cut -f1 -d",")

	instanceReachability=$(ipTools.sh describesgingress $STACKNAME)

	if [ "$instanceReachability" == "No access to security group" ]; then
		echo "instance not reachable with current security group rules"
		echo "please run: "
		echo "  ipTools.sh updatesgingress $STACKNAME"
		exit 1
	fi
	#run EC2 instances: https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
	# https://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-launch.html
	if [[ $EBSVOLUMESIZEGB > 1 ]]; then
		if [ $EC2RUNARGUMENT == "createAMI" ]; then
			
		EC2RunOutput=$(aws ec2 run-instances \
			--tag-specifications 'ResourceType=instance,Tags={Key=Name,Value="'$INSTANCENAME'"}' \
			--image-id $TEMPLATEIMAGEID \
			--security-group-ids $SECURITYGROUPS \
			--count 1 \
			--instance-type $INSTANCETYPE \
			--key-name $KEYNAME \
			--subnet-id $SUBNET \
			--block-device-mappings 'DeviceName=/dev/sdb,Ebs={VolumeSize="'$EBSVOLUMESIZEGB'",DeleteOnTermination=true,Encrypted=false,VolumeType=gp2}')
		else
		EC2RunOutput=$(aws ec2 run-instances \
			--tag-specifications 'ResourceType=instance,Tags={Key=Name,Value="'$INSTANCENAME'"}' \
			--image-id $TEMPLATEIMAGEID \
			--security-group-ids $SECURITYGROUPS \
			--count 1 \
			--instance-type $INSTANCETYPE \
			--key-name $KEYNAME \
			--subnet-id $SUBNET \
			--launch-template LaunchTemplateId=$LAUNCHTEMPLATEID \
			--block-device-mappings 'DeviceName=/dev/sdb,Ebs={VolumeSize="'$EBSVOLUMESIZEGB'",DeleteOnTermination=true,Encrypted=false,VolumeType=gp2}' )
		fi

	else

		if [ $EC2RUNARGUMENT == "createAMI" ]; then
			
			EC2RunOutput=$(aws ec2 run-instances \
				--tag-specifications 'ResourceType=instance,Tags={Key=Name,Value="'$INSTANCENAME'"}' \
				--image-id $TEMPLATEIMAGEID \
				--security-group-ids $SECURITYGROUPS \
				--count 1 \
				--instance-type $INSTANCETYPE \
				--key-name $KEYNAME \
				--subnet-id $SUBNET)
		else
			EC2RunOutput=$(aws ec2 run-instances \
				--tag-specifications 'ResourceType=instance,Tags={Key=Name,Value="'$INSTANCENAME'"}' \
				--image-id $TEMPLATEIMAGEID \
				--security-group-ids $SECURITYGROUPS \
				--count 1 \
				--instance-type $INSTANCETYPE \
				--key-name $KEYNAME \
				--subnet-id $SUBNET \
				--launch-template LaunchTemplateId=$LAUNCHTEMPLATEID)
		fi

	fi

	echo "EC2RunOutput=$EC2RunOutput"
	echo ""

	#status
	IFS=$'\t'
	vars=$(echo $EC2RunOutput | grep INSTANCES)
	# instanceID 8th column i-00f88ef1c7ca1820e
	instanceID=$(echo $vars  | awk '//{print $7}')
	echo "instanceID=$instanceID"


	# Progress can be seen here: 	# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:sort=instanceId
	AWSREGION=$(aws configure get region)
	echo "-----------------------------------------------------------------------------------------"
	echo "Instance state progress can be seen here:"
	echo "https://console.aws.amazon.com/ec2/v2/home?region=${AWSREGION}#Instances:sort=instanceId"
	echo "-----------------------------------------------------------------------------------------"

	#get instance status and wait for it to run
	# RUNNING or ???  TERMINATED  (actually returns nothing) second row third column


	systemstatus=$(getinstance.sh $instanceID systemstatus)
	systemtime=0
	echo "Starting EC2 instance. This will take a few minutes: "
	echo "|-----------------------|"
	echo -n "["
	while [ "$systemstatus" != "ok" ]
	do
		systemstatus=$(getinstance.sh $instanceID systemstatus) 
		echo -n "."
		sleep 10s
		systemtime=$((systemtime+10))
	done
	echo "]"
	echo " Instance:  $instanceID  created in $systemtime seconds"

	# create file to store variables related to instance
	# get IP address, and hostname (#TODO, get public hostname)
	instanceIPInternal=$(getinstance.sh $instanceID ipaddress)
	instanceHostNameInternal=$(getinstance.sh $instanceID hostname)
	instanceIPPublic=$(getinstance.sh $instanceID ipaddresspublic)
	instanceHostNamePublic=$(getinstance.sh $instanceID hostnamepublic)
	instanceFile=~/.batchawsdeploy/instance_${STACKNAME}_${INSTANCENAME}_${instanceHostNamePublic}
	touch $instanceFile
	echo "#!/bin/bash" > $instanceFile
	echo "INSTANCENAME=$INSTANCENAME" >> $instanceFile
	echo "instanceID=$instanceID" >> $instanceFile
	echo "instanceIP=$instanceIP" >> $instanceFile
	echo "instanceHostNameInternal=$instanceHostNameInternal" >> $instanceFile
	echo "instanceIPPublic=$instanceIPPublic" >> $instanceFile
	echo "instanceHostNamePublic=$instanceHostNamePublic" >> $instanceFile

	#------------------------------------------------------------------------------------------------
	#TODO: redo all input arguments and put an argument specifically for if I want to copy the configs
	#TODO: change absolute paths
	#------------------------------------------------------------------------------------------------

	#remove previous keys with this hostname
	ssh-keygen -f "~/.ssh/known_hosts" -R $instanceHostNamePublic

	if [ $EC2RUNARGUMENT != "createAMI" ]; then
		# Docs on the proper way to ssh
		# https://superuser.com/questions/187779/too-many-authentication-failures-for-username
		# https://serverfault.com/questions/36291/how-to-recover-from-too-many-authentication-failures-for-user-root

		# don't check identity on first connect
		SSH_OPTIONS="-o IdentitiesOnly=yes" # -v
		echo "Creating remote directories"
		ssh ec2-user@${instanceHostNamePublic} -i ${KEYPATH} $SSH_OPTIONS \
		-o StrictHostKeyChecking=no "mkdir -p /home/ec2-user/.aws/"
		ssh ec2-user@${instanceHostNamePublic} -i ${KEYPATH} $SSH_OPTIONS \
		"mkdir -p /home/ec2-user/.batchawsdeploy/"
		ssh ec2-user@${instanceHostNamePublic} -i ${KEYPATH} $SSH_OPTIONS \
		"mkdir -p /home/ec2-user/.nextflow/"

		echo "Copying Necessary files for remote administration"
		scp -i ${KEYPATH} $SSH_OPTIONS \
		$BATCHAWSCONFIGFILE ec2-user@${instanceHostNamePublic}:/home/ec2-user/.batchawsdeploy/
		scp -i ${KEYPATH} $SSH_OPTIONS \
		$KEYPATH ec2-user@${instanceHostNamePublic}:/home/ec2-user/.batchawsdeploy/
		scp -i ${KEYPATH} $SSH_OPTIONS \
		~/.aws/config ec2-user@${instanceHostNamePublic}:/home/ec2-user/.aws/
		scp -i ${KEYPATH} $SSH_OPTIONS \
		~/.aws/credentials ec2-user@${instanceHostNamePublic}:/home/ec2-user/.aws/

		# create an empty file named "environment_aws" to signify that this is an ec2 instance
		touch dummyfile
		scp -i ${KEYPATH} $SSH_OPTIONS dummyfile \
		ec2-user@${instanceHostNamePublic}:/home/ec2-user/.batchawsdeploy/environment_aws
		rm dummyfile

		# Nextflow Configuration
		scp -i ${KEYPATH} $SSH_OPTIONS \
		~/.nextflow/config ec2-user@${instanceHostNamePublic}:/home/ec2-user/.nextflow/

		# Scripts for running the head node
		#scp -i ${KEYPATH} launchEC2HeadNode.sh ec2-user@${instanceHostNamePublic}:/home/ec2-user/
		scp -i ${KEYPATH} $SSH_OPTIONS \
		startHeadNode.sh ec2-user@${instanceHostNamePublic}:/home/ec2-user/

		echo "To re-connect to this instance later run:"
		echo "ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic}"
		echo "-------------------------------------------------------"
		echo "To copy files to this instance run:"
		echo "scp -i ${KEYPATH} MYFILENAME ec2-user@${instanceHostNamePublic}:/home/ec2-user/"
		echo "-------------------------------------------------------"
		echo "To shutdown this instance, exit the instance and run:"
		echo "aws ec2 terminate-instances --instance-id $instanceID"
		echo "-------------------------------------------------------"
	fi

	#6.) SSH into the host and run the configure script then close it and create an AMI based on this image
		# ssh trick to not check host KEYPATH https://linuxcommando.blogspot.com/2008/10/how-to-disable-ssh-host-key-checking.html
		#  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
		# run local script on remote host with ssh: 
		# https://stackoverflow.com/questions/305035/how-to-use-ssh-to-run-a-shell-script-on-a-remote-machine 
	echo "-------------------------------------------------------"
	echo "-------------------------------------------------------"
	###########################################################
	#########      EC2RunArgument=runscript           #########
	###########################################################
	if [[ $EC2RUNARGUMENT == "runscript_attached" ]]; then
		echo "SSH attached mode..."
		ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS \
			'bash -s' < ${SCRIPTPATH}
	###########################################################
	#######    EC2RunArgument=runscript_detached        #######
	###########################################################
	elif [[ $EC2RUNARGUMENT == "runscript_detached" ]]; then
		echo "SSH detached mode..."
		#Copy the script for remote excution in detached mode
		scp -i ${KEYPATH} $SSH_OPTIONS \
                $SCRIPTPATH ec2-user@${instanceHostNamePublic}:/home/ec2-user/
		ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS \
			"./home/ec2-user/${SCRIPTNAME} </dev/null >/var/log/root-backup.log 2>&1 &"

		#cat ${SCRIPTPATH} | ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS "./home/ec2-user/${SCRIPTNAME} </dev/null >/var/log/root-backup.log 2>&1 &"
		cat ${SCRIPTPATH} | ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS 'bash -'

	###########################################################
	#######      EC2RunArgument=directconnect           #######
	###########################################################
	elif [[ $EC2RUNARGUMENT == "directconnect" ]]; then
		echo "SSH direct connect"
		ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS
	###########################################################
	#########      EC2RunArgument=createAMI           #########
	###########################################################
	elif [[ $EC2RUNARGUMENT == "createAMI" ]]; then
		echo "EC2RUNARGUMENT=$EC2RUNARGUMENT"
		ssh -i ${KEYPATH} ec2-user@${instanceHostNamePublic} $SSH_OPTIONS \
			'bash -s' < ${SCRIPTPATH}
		echo "----------------------------------------"
		echo "----------------------------------------"
		echo "Check for any errors in the AMI creation:"

		imageID=$(aws ec2 create-image --instance-id $instanceID --name BLJAMI${AMIIDENTIFIER}-${EBSVOLUMESIZEGB}GB_DOCKER)
		imageStatus=$(getec2images.sh $imageID status)
		echo "Creating AMI. This may take a minute"
		echo "|--------------------|"
		echo -n "<."
		imagetime=0
		while [ "$imageStatus" != "available" ]
		do
			imageStatus=$(getec2images.sh $imageID status)
			echo -n "."
			sleep 5s
			imagetime=$((imagetime+5))
		done
		echo -n ".>"
		echo " Instance:  $imageID  created in $imagetime seconds"

		#TAG the image as defined by the two tag values (used for filtering if this image was already created)
		aws ec2 create-tags --resources $imageID --tags Key=$IMAGETAG,Value=$IMAGETAGVALUE
		echo $imageID
		aws ec2 terminate-instances --instance-ids $instanceID
	fi

else
	print_help
	"number of arguments provided: $#"
fi



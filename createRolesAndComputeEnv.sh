#!/bin/bash

# This script creates the IAM roles and compute environment necessary to run the BioLockJ Genomics pipeline
# variable names and iam template drawn fromfrom the AWS batch genomics tutorial pipeline (below) and modified to work with NextFlow.
# https://github.com/aws-samples/aws-batch-genomics/blob/master/README.md

#Things only created once: IAM stack, security group, network (one public, one private/or use the default?  What about one in between???)

#Questions for Sarah:  EBS.  Am I provisioning 1TB for one instance or for each instance?
# subnets? Security groups?  Which do I create, need a public IP?

#PUBLIC image created 12_12_2018
#BLJAMImanager-50GB_DOCKER   ami-01a9c10af27d4d2a8    725685564787/BLJAMImanager-50GB_DOCKER    725685564787

#TODO: Automatically print out nextflow.config template, filled in.
#  including the access key and secret key?  restrict file access for config file to "user"??  
#   or should I use the .pem

#TODO: might delete the original compute environments since they have a different AMI??
#TODO: create a random S3 bucket, try to keep it as empty as possible


#NOTE: You get a maximum of 5 VPCS per region, each different stack name creates its own VPC
SECONDS=0

if [ $# -eq 6 ]; then

	STACKNAME=$1
	COMPUTEENVIRONMENTNAME=$2
	QUEUENAME=$3
	SPOTPERCENT=$4
	MAXCPU=$5
	EBSVOLUMESIZEGB=$6
	#VERBOSE=$7
	#IMAGEID=$4

	ACCOUNTID=$(./getawsaccountid.sh)
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	DESIREDCPUS=0 #this is the minimum reserved CPUS.  Specifying more than 0 will waste money unless you are putting out batch jobs 24/7

	#TODO: create a seperate script for the compute environment
	#computeenvstatus=$()

	#Global Parameters
	KEYNAME=BioLockJKeyPairAMI
	#Stack Parameters
	STACKFILE=BLJStack.yml
	#AMI Parameters
	#this is only the instance type for creating AMIs
	INSTANCETYPEFORAMICREATION=t2.micro  
	TEMPLATEIMAGEID=ami-0b9a214f40c38d5eb  #latest as of 2018oct17
	EBSVOLUMESIZEGB="50"
	#Additional identifiers for AMI
	AMIIDENTIFIER=manager
	IMAGETAG=ImageRole
	IMAGETAGVALUE=BLJManager
	#Compute Environment Parameters
	#TODO: check if compute environment exists!!!
	COMPUTEENVPRIORITY=10



	# reduce the last number to be more leniant about ip a ddresses, for example if a university has multiple IPs
	#Get local public IPaddress https://askubuntu.com/questions/95910/command-for-determining-my-public-ip 
	# curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'  
	MYPUBLICIPADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
	MASK=32
	MYPUBLICIPADDRESS=${MYPUBLICIPADDRESS}"/"${MASK}
	echo "My Public IPAddress: $MYPUBLICIPADDRESS"

	#1.) Check for key and create if it doesn't exist.  This is a keypair for ssh into EC2.
	./awskeypair.sh create $KEYNAME
	#TODO: 1.a) also create secret access key: aws iam create-access-key --user-name  for nextflow login instead of SSH
	#option to create and delete one of these on every run for extra security??????
	#TODO: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey_CLIAPI


	#1.) check if stack exists
	#2.) if it doesn't ask if you want to create it
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	if [ "$stackstatus" == "Stack exists" ]; then
		echo $stackstatus
	else
		# while true; do
  #   		read -p "Stack $STACKNAME does not exist. Do you want to create it?: " yn
  #   		case $yn in
  #       		[Yy]* ) ./createcloudformationstack.sh ${STACKNAME} $STACKFILE ParameterKey=\"NetworkAccessIP\",ParameterValue="$MYPUBLICIPADDRESS"; break;;
  #       		[Nn]* ) exit;;
  #       		* ) echo "Please answer yes or no.";;
  #   		esac
		#  done
		./createcloudformationstack.sh ${STACKNAME} $STACKFILE ParameterKey=\"NetworkAccessIP\",ParameterValue="$MYPUBLICIPADDRESS"
		#TODO: stack events https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-events.html
		#https://www.tecmint.com/awk-print-fields-columns-with-space-separator/
		#Bastion: https://github.com/bonusbits/cloudformation_templates/blob/master/infrastructure/archive/bastion.json

		#echo $stackcreatedstatus 
		#TODO: if the user doesn't want to create it,  
		# then say that there are no suitable compute environments, or check for sutiable environments?
	fi

	#3.) check if stack exists once more
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	if [ "$stackstatus" == "Stack exists" ]; then
		SERVICEROLE=$(./getcloudformationstack.sh $STACKNAME BatchServiceRoleArn)
		echo "Service Role: $SERVICEROLE"
		#TODO: check these aren't empty
		IAMFLEETROLE=$(./getcloudformationstack.sh $STACKNAME SpotIamFleetRoleArn)
		IAMFLEETROLE=arn:aws:iam::${ACCOUNTID}:role/${IAMFLEETROLE}
		echo "Spot Fleet Role: $IAMFLEETROLE"
		#JOBROLEARN=$(./getcloudformationstack.sh $STACKNAME ecsTaskRole)
		
		#INSTANCEROLE=$(./getcloudformationstack.sh $STACKNAME EcsInstanceRoleArn)
		#INSTANCEROLE=arn:aws:iam::${ACCOUNTID}:role/${INSTANCEROLE}
		INSTANCEROLE=$(./getcloudformationstack.sh $STACKNAME IamInstanceProfileArn)
		INSTANCEROLE=arn:aws:iam::${ACCOUNTID}:instance-profile/${INSTANCEROLE}
		echo "Instance Role: $INSTANCEROLE"

		#Note: creating a security group with IP rules?  See  Page 6 of Creating a new AMI
		# allows security group creation for each instance?  Public for web facing, private for batch?
		BASTIONSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BastionSecurityGroup)
		#BATCHSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BatchSecurityGroup)  #TODO: change the json and this to have a name that returns a different value
		BATCHSECURITYGROUP=$BASTIONSECURITYGROUP  #TODO delete this and uncomment later
		echo "Bastion Security Group $BASTIONSECURITYGROUP"
		SUBNETS=$(./getcloudformationstack.sh $STACKNAME Subnet)  #replaced getsubnets
		echo "subnets: $SUBNETS"


		#2.) Check for AMI
		#If it doesn't exist create the stack then create the AMI
		#Check if AMI tagged exists
		imageTagStatus=$(./getec2images.sh tags $IMAGETAG $IMAGETAGVALUE)
		imageExistWordCount=$(echo -n $imageTagStatus | wc -m)
		if [[ $imageExistWordCount -lt 2 ]]; then
		# while true; do
  #   		read -p "Image with tag: ${IMAGETAG}, value: ${IMAGETAGVALUE} does not exist. Do you want to create it?: " yn
  #   		case $yn in
  #       		[Yy]* ) ./createAMI.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPEFORAMICREATION $KEYNAME $EBSVOLUMESIZEGB $AMIIDENTIFIER $STACKFILE $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS; break;;
  #       		[Nn]* ) exit;;
  #       		* ) echo "Please answer yes or no.";;
  #   		esac
		# done
		./createAMI.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPEFORAMICREATION $KEYNAME $EBSVOLUMESIZEGB $AMIIDENTIFIER $STACKFILE $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS
		fi
		#image ID is the 6th column in the outputstring
		imageID=$(echo $imageTagStatus | grep IMAGES | grep ami | awk '//{print $6}')


		# alternatively list available AMIs?

		#TODO: add optional parameters at the end for subnet?  see README.md on how to do this...

		# do we need to create a keypair also?
		# aws ec2 create-key-pair
		#aws ec2 register-image?   
			#create-image 
			#import-image

		#REGISTRY=
		#REPO_URI= 725685564787.dkr.ecr.us-east-1.amazonaws.com/isaac
		#ENV=$COMPUTEENVIRONMENTNAME

		# Pass control
		# give aaron list of paramaters
		# make a checkbox for each item in a csv?

		#TODO: removed ec2 keypair.... might need to put this back in???
		
		#TODO: need to put it in two security groups

		# batchCreatOutput=$(aws batch create-compute-environment --compute-environment-name $COMPUTEENVIRONMENTNAME \
		# --type MANAGED --state ENABLED --service-role ${SERVICEROLE} \
		# --compute-resources type=SPOT,minvCpus=0,maxvCpus=$MAXCPU,desiredvCpus=$DESIREDCPUS,instanceTypes=optimal,imageId=$imageID,subnets=$SUBNETS,securityGroupIds=$BATCHSECURITYGROUP,instanceRole=$INSTANCEROLE,bidPercentage=$SPOTPERCENT,spotIamFleetRole=$IAMFLEETROLE)
		# echo "creating compute environment: $COMPUTEENVIRONMENTNAME"
		# echo "$batchOutput"
		# sleep 10s
		batchCreatOutput=$(aws batch create-compute-environment --compute-environment-name $COMPUTEENVIRONMENTNAME \
		--type MANAGED --state ENABLED --service-role ${SERVICEROLE} \
		--compute-resources type=SPOT,minvCpus=0,maxvCpus=$MAXCPU,desiredvCpus=$DESIREDCPUS,instanceTypes=optimal,imageId=$imageID,subnets=$SUBNETS,securityGroupIds=$BATCHSECURITYGROUP,ec2KeyPair=$KEYNAME,instanceRole=$INSTANCEROLE,bidPercentage=$SPOTPERCENT,spotIamFleetRole=$IAMFLEETROLE)
		echo "creating compute environment: $COMPUTEENVIRONMENTNAME"
		echo "$batchOutput"
		sleep 10s

		#.) Create Job Queue
		queueCreateOutput=$(aws batch create-job-queue --job-queue-name $QUEUENAME \
			--compute-environment-order order=0,computeEnvironment=$COMPUTEENVIRONMENTNAME  \
			--priority $COMPUTEENVPRIORITY \
			--state ENABLED)

		echo "FINISHED!"
		echo "FINISHED!"
		echo "FINISHED!"
		echo "BLJ Stack, AMI, and compute environment deployed in: $SECONDS seconds"
		#TODO create High and low priority like in the tutorial later, with linked Queues and one that is ON DEMAND
	else
		echo "stack could not be found or created"
	fi

else
	echo "Your command line contains $# arguments"
	echo "usage: six arguments: "
	echo " ./createRolesAndComputeEnv.sh STACKNAME COMPUTEENVIRONMENTNAME SPOTPRICE QUEUENAME IMAGEIDNUM MAXCPU EBSVOLUMESIZEGB"

fi

#TODO: more error handling about creation of compute environmet and all necessary resources
#TODO: See error screenshot created 2018-10-24- Around 12:58pm  Wrong ECSInstance role???!
#TODO: Check for errors occassionally in malformed Environment or Queue (see screenshot and compute environment 10?  "Status")

#TODO: fix arn gets from cloudformation output
#TODO: check that all instance profiles and roles exist in advance.

#TODO: try putting the key parameter back into the batch


# important note: not having S3 access in the original template was causing S3 puts to fail from nextflow running on the instance:
# https://groups.google.com/forum/#!msg/nextflow/87hI5C831Ok/2pgdP5FOBwAJ

# ./createRolesAndComputeEnv.sh BLJStack1 BLJComputeEnvironment1 BLJQueue1 60 1024
#TO READ: https://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-sg.html#configuring-a-security-group

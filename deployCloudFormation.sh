#!/bin/bash

# This script creates the IAM roles and compute environment necessary to run the BioLockJ Genomics pipeline
# variable names and iam template drawn fromfrom the AWS batch genomics tutorial pipeline (below) and modified to work with NextFlow.
# https://github.com/aws-samples/aws-batch-genomics/blob/master/README.md

#Things only created once: IAM stack, security group, network (one public, one private/or use the default?  What about one in between???)

#TODO: There are currently several hardcoded values for us-east-1
#TODO: autocreate an IAM role with the minimal capabilities and paste it into aws config

#TODO: error handling for compute environment and job queue that already exist
#TO READ: https://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-sg.html#configuring-a-security-group

SECONDS=0

# exit when any command fails
set -e

if [ $# -eq 10 ]; then

	STACKNAME=$1
	source ~/.batchawsdeploy/config
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE

	SPOTPERCENT=$2
	SPOTMAXVCPUS=$3
	ONDEMANDMAXVCPUS=$4
	DEFAULTAMI=$5
	CUSTOMAMIFOREFS=$6
	EBSVOLUMESIZEGB=$7
	EFSPERFORMANCEMODE=$8
	NEXTFLOWCONFIGOUTPUTDIRECTORY=$9
	KEYNAME=${10}

	echo "STACKNAME=$STACKNAME" >> $BATCHAWSCONFIGFILE
	echo "KEYNAME=$KEYNAME" >> $BATCHAWSCONFIGFILE
	# echo "COMPUTEENVIRONMENTNAME=$COMPUTEENVIRONMENTNAME"  >> $BATCHAWSCONFIGFILE
	# echo "QUEUENAME=$QUEUENAME"  >> $BATCHAWSCONFIGFILE
	echo "SPOTPERCENT=$SPOTPERCENT"  >> $BATCHAWSCONFIGFILE
	echo "EBSVOLUMESIZEGB=$EBSVOLUMESIZEGB" >> $BATCHAWSCONFIGFILE
	echo "SPOTMAXVCPUS=$SPOTMAXVCPUS"  >> $BATCHAWSCONFIGFILE
	echo "DEFAULTAMI=$DEFAULTAMI"  >> $BATCHAWSCONFIGFILE

	ACCOUNTID=$(getawsaccountid.sh)
	#stackstatus=$(getcloudformationstack.sh $STACKNAME)
	DESIREDCPUS=0 #this is the MINIMUM reserved CPUS
	echo "DESIREDCPUS=$DESIREDCPUS" >> $BATCHAWSCONFIGFILE

	##################################################
	# AMI Parameters for Custom AMI
	##################################################
	#this is only the instance type for creating AMIs
	#ami-0b9a214f40c38d5eb #latest as of 2018oct17
	TEMPLATEIMAGEID=ami-00a0ec1744b47e7e3
	INSTANCETYPEFORAMICREATION=t2.micro

	##################################################
	# Compute Environment Parameters
	#TODO: check if compute environment exists!!!
	COMPUTEENVPRIORITY=10
	echo "COMPUTEENVPRIORITY=$COMPUTEENVPRIORITY"

	#######################################################################################
	# 0.a) S3 Bucket
	# Check if S3 bucket with name beginning with $STACKNAME exists. If not, create it.
	# Note: the S3 buckets must be GLOBALLY unique. 
	# A random string is appended to the stackname to make duplicates less probably
	#######################################################################################
	echo "----------------------------------------------------------------------"
	echo "0.) S3 Bucket: "
	echo "----------------------------------------------------------------------"
	#TODO: rand generator not yet tested on LINUX:
	#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
	#TODO: set more permissions
	#check for BLJ bucket (TODO: turn this into a function)
	if [ -z $S3BUCKETNAME ]; then
		s3Tools.sh $STACKNAME create autogenerate createdirstructure
	fi

	#######################################################################################
	#STACK and Cloudformation Parameters 
	#######################################################################################
	#TODO: allow for custom stackfile
	STACKFILE=${BATCHAWSDEPLOY_HOME}BLJStackEFSCompute.yml
	echo "STACKFILE=$STACKFILE"
	echo "STACKFILE=$STACKFILE" >> $BATCHAWSCONFIGFILE

	MYPUBLICIPADDRESS=$(ipTools.sh getip)
	echo "MYPUBLICIPADDRESS=$MYPUBLICIPADDRESS" >> $BATCHAWSCONFIGFILE

	# 0.b)Check for key and create if it doesn't exist.  This is a keypair for ssh into EC2.
	awskeypair.sh create $KEYNAME
	KEYPATH=~/.batchawsdeploy/key_${KEYNAME}.pem
	echo "KEYPATH=$KEYPATH"
	echo "KEYPATH=$KEYPATH" >> $BATCHAWSCONFIGFILE
	#TODO: 1.a) also create secret access key: aws iam create-access-key --user-name  for nextflow login instead of SSH
	#option to create and delete one of these on every run for extra security??????
	#TODO: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey_CLIAPI

	#######################################################################################
	#1.) check if stack exists
	#######################################################################################
	echo "----------------------------------------------------------------------------------------------"
	echo "1.) Deploy Cloudformation Stack  -------------------------------------------------------------"
	echo "----------------------------------------------------------------------------------------------"
	stackstatus=$(getcloudformationstack.sh $STACKNAME)
	#"stackexists" is hardcoded in:
	# deployCloudFormation.sh, 2x createcloudformationstack.sh, getcloudformationstack.sh
	if [ "$stackstatus" == "CREATE_COMPLETE" ]; then
		echo $stackstatus
	else
		createcloudformationstack.sh ${STACKNAME} $STACKFILE \
		"ParameterKey=\"NetworkAccessIP\",ParameterValue="$MYPUBLICIPADDRESS" \
		ParameterKey=\"SpotBidPercentage\",ParameterValue="$SPOTPERCENT" \
		ParameterKey=\"SpotBatchMaxvCPUs\",ParameterValue="$SPOTMAXVCPUS" \
		ParameterKey=\"OnDemandBatchMaxvCPUs\",ParameterValue="$ONDEMANDMAXVCPUS" " # \ 
		#|| { echo "createcloudformationstack failed outside script"; exit 1; }
		stackstatus=$(getcloudformationstack.sh $STACKNAME)
	fi
	#######################################################################################SpotBidPercentage
	#1.b) check if stack exists once more
	#######################################################################################
	stackstatus=$(getcloudformationstack.sh $STACKNAME)
	if [ "$stackstatus" == "CREATE_COMPLETE" ]; then
		SERVICEROLE=$(getcloudformationstack.sh $STACKNAME BatchServiceRoleArn)
		echo "SERVICEROLE=$SERVICEROLE" >> $BATCHAWSCONFIGFILE
		#TODO: check these aren't empty
		IAMFLEETROLE=$(getcloudformationstack.sh $STACKNAME SpotIamFleetRoleArn)
		IAMFLEETROLE=arn:aws:iam::${ACCOUNTID}:role/${IAMFLEETROLE}
		echo "IAMFLEETROLE=$IAMFLEETROLE" >> $BATCHAWSCONFIGFILE
		JOBROLEARN=$(getcloudformationstack.sh $STACKNAME ECSTaskRole)
		echo "JOBROLEARN=$JOBROLEARN" >> $BATCHAWSCONFIGFILE
		
		INSTANCEROLE=$(getcloudformationstack.sh $STACKNAME IamInstanceProfileArn)
		INSTANCEROLE=arn:aws:iam::${ACCOUNTID}:instance-profile/${INSTANCEROLE}
		echo "INSTANCEROLE=$INSTANCEROLE" >> $BATCHAWSCONFIGFILE

		#Note: creating a security group with IP rules?  See  Page 6 of Creating a new AMI
		# allows security group creation for each instance?  Public for web facing, private for batch?
		BASTIONSECURITYGROUP=$(getcloudformationstack.sh $STACKNAME BastionSecurityGroup)
		#BATCHSECURITYGROUP=$(getcloudformationstack.sh $STACKNAME BatchSecurityGroup)  
		#TODO: change the json and this to have a name that returns a different value
		BATCHSECURITYGROUP=$BASTIONSECURITYGROUP #TODO delete this and uncomment later

		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"

		echo "BATCHSECURITYGROUP=$BATCHSECURITYGROUP" >> $BATCHAWSCONFIGFILE
		echo "BASTIONSECURITYGROUP=$BASTIONSECURITYGROUP" >> $BATCHAWSCONFIGFILE
		SUBNETS=$(getcloudformationstack.sh $STACKNAME Subnet)
		echo "SUBNETS=$SUBNETS" >> $BATCHAWSCONFIGFILE
		efsID=$(getcloudformationstack.sh $STACKNAME FileSystemId)

		HEADNODELAUNCHTEMPLATEID=$(getcloudformationstack.sh $STACKNAME HeadNodeLaunchTemplateId)
		echo "HEADNODELAUNCHTEMPLATEID=$HEADNODELAUNCHTEMPLATEID" >> $BATCHAWSCONFIGFILE

		BATCHNODELAUNCHTEMPLATEID=$(getcloudformationstack.sh $STACKNAME BatchNodeLaunchTemplateId)
		echo "BATCHNODELAUNCHTEMPLATEID=$BATCHNODELAUNCHTEMPLATEID" >> $BATCHAWSCONFIGFILE
		#Name might be better to use later, will need to label it as an output under outputs! 
		#LaunchTemplateName=$(getcloudformationstack.sh $STACKNAME LaunchTemplateName)

        #######################################################################################
		#1.c) Check for AMI (depricated)
		#######################################################################################
		IMAGEID=$DEFAULTAMI
		echo "IMAGEID=$IMAGEID" >> $BATCHAWSCONFIGFILE

		################################################################################################
		#2.) Create Batch Computing environment
		####################################################################################################
		
		SPOTCOMPUTEENVIRONMENTNAME=$(getcloudformationstack.sh $STACKNAME SpotComputeEnv)
		JOBQUEUELOWPRIORITYNAME=$(getcloudformationstack.sh $STACKNAME LowPriorityJobQueue)
		SPOTCOMPUTEENVIRONMENTNAME=$(getcloudformationstack.sh $STACKNAME OnDemandComputeEnv)
		JOBQUEUEHIGHPRIORITYNAME=$(getcloudformationstack.sh $STACKNAME HighPriorityJobQueue)
		echo "SPOTCOMPUTEENVIRONMENTNAME=$SPOTCOMPUTEENVIRONMENTNAME" >> $BATCHAWSCONFIGFILE
		echo "JOBQUEUELOWPRIORITYNAME=$JOBQUEUELOWPRIORITYNAME" >> $BATCHAWSCONFIGFILE

		#######################################################################################
		#6.) Print success message
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		timeinminutes=$(awk "BEGIN {print $SECONDS/60}")
		echo "SUCCESS!"
		echo -n "STACK: $STACKNAME, S3 Bucket, EFS, compute environment,"
		echo " Job Queue deployed in: $timeinminutes minutes ($SECONDS seconds)"
		echo "----------------------------------------------------------------------------------------------"

		#######################################################################################
		#3.) Create Job Definition
		# Create ONE Job defintion for ONE container
		# The purpose of creating a seperate job definition to work with nextflow is that
		# containers need to be declared as "priviledged" in order to mount EFS volumes.
		# This script will have to be run for every job definition you wish to run
		# and only re-run if you want to change the actual name of the IMAGE
		# this will then output a new nextflow config file
		# Note, the cpus and memory can be overridden at runtime in each nextflow process.
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		echo "3.) Create Job Definition  -------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"
		echo "command: updateBatchJobDefinitions.sh $STACKNAME"
		BatchJobsDeployOutput=$(updateBatchJobDefinitions.sh $STACKNAME)
		echo "$BatchJobsDeployOutput"
		echo "$BatchJobsDeployOutput" >> $BATCHAWSCONFIGFILE
		echo "----------------------------------------------------------------------------------------------"

		echo "----------------------------------------------------------------------------------------------"
		echo "4.) Print Nextflow Config   ------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"
		echo "command: printnextflowconfig.sh $STACKNAME"
		nextflowconfig=$(printnextflowconfig.sh $STACKNAME)
		echo "$nextflowconfig"
		echo "$nextflowconfig" > "${NEXTFLOWCONFIGOUTPUTDIRECTORY}config"
		echo "--------------------------------------------------------------------------------------------------------------"
		echo -n "--------------------------------------------------------------------------------------------------------------"
echo -n '
                  ___  _       __   _____                  ____            __            __                
                 /   || |     / /  / ___/                 / __ )  ____ _  / /_  _____   / /_               
                / /| || | /| / /   \__ \                 / __  | / __ `/ / __/ / ___/  / __ \              
               / ___ || |/ |/ /   ___/ /                / /_/ / / /_/ / / /_  / /__   / / / /              
              /_/  |_||__/|__/   /____/                /_____/  \__,_/  \__/  \___/  /_/ /_/               
   ______                                     _                          _____   __                    __  
  / ____/  ___    ____   ____    ____ ___    (_)  _____   _____         / ___/  / /_  ____ _  _____   / /__
 / / __   / _ \  / __ \ / __ \  / __ `__ \  / /  / ___/  / ___/         \__ \  / __/ / __ `/ / ___/  / //_/
/ /_/ /  /  __/ / / / // /_/ / / / / / / / / /  / /__   (__  )         ___/ / / /_  / /_/ / / /__   / ,<   
\____/   \___/ /_/ /_/ \____/ /_/ /_/ /_/ /_/   \___/  /____/         /____/  \__/  \__,_/  \___/  /_/|_|  
                                                                                                          
'
		echo "--------------------------------------------------------------------------------------------------------------"
		echo "--------------------------------------------------------------------------------------------------------------"
		infrastructureScriptStatus=SUCCESS  #or FAILURE
		echo "infrastructureScriptStatus=$infrastructureScriptStatus"
		echo "9.) Configuration files saved to: "
		echo "$BATCHAWSCONFIGFILE"
		echo "-----------------------------------------------------------------------------------"
		echo "10.a) Launch EC2 and run script directly:  ----------------------------------------"
		echo "    -This option runs a script directly through ssh on the head node"
		echo "EC2Node.sh runscript_detached $STACKNAME HeadNode t2.micro startHeadNodeGui.sh"
		echo "-----------------------------------------------------------------------------------"		
		echo "10.b) Launch EC2 and connect directly:  -------------------------------------------"
		echo "     -This option runs an EC2 instance, copies associated credentials and"
		echo "     creates an ssh connect directly to the headnode"
		echo "EC2Node.sh directconnect $STACKNAME HeadNode t2.micro"
		echo "-----------------------------------------------------------------------------------"
		echo "CREATE_COMPLETE"

	else
		#delete stack just in case
		#aws cloudformation delete-stack --stack-name $STACKNAME
		#deleting key
		#echo "deleting keypair:"
		#awskeypair.sh delete $KEYNAME
		echo "CREATE_FAILED stack could not be created"
		exit 1
	fi
else
	echo "Your command line contains $# arguments"
	echo "usage: 12 arguments: "
	echo -n " deployCloudFormation.sh STACKNAME SPOTPERCENT SPOTMAXVCPUS ONDEMANDMAXVCPUS DEFAULTAMI "
	echo "CUSTOMAMIFOREFS EBSVOLUMESIZEGB EFSPERFORMANCEMODE DOCKERREPOSEARCHSTRING"
	exit 1
fi



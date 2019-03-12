#!/bin/bash

# This script creates the IAM roles and compute environment necessary to run the BioLockJ Genomics pipeline
# variable names and iam template drawn fromfrom the AWS batch genomics tutorial pipeline (below) and modified to work with NextFlow.
# https://github.com/aws-samples/aws-batch-genomics/blob/master/README.md

#Things only created once: IAM stack, security group, network (one public, one private/or use the default?  What about one in between???)

#TODO: There are currently several hardcoded values for us-east-1
#TODO: create High and low priority like in the tutorial later, with linked Queues and one that is ON DEMAND
#TODO: autocreate an IAM role with the minimal capabilities and paste it into aws config

#TODO: EFS
# The PerformanceMode of the file system.   https://docs.aws.amazon.com/cli/latest/reference/efs/create-file-system.html
# We recommend generalPurpose performance mode for most file systems. File systems using the maxIO 
# performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of 
# slightly higher latencies for most file operations. This can't be changed after the file system has been created.

#TODO: error handling for compute environment and job queue that already exist

SECONDS=0

if [ $# -eq 11 ]; then

	STACKNAME=$1
	source ~/.batchawsdeploy/config
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE

	COMPUTEENVIRONMENTNAME=$2
	QUEUENAME=$3
	SPOTPERCENT=$4
	MAXCPU=$5
	DEFAULTAMI=$6
	CUSTOMAMIFOREFS=$7
	EBSVOLUMESIZEGB=$8
	EFSPERFORMANCEMODE=$9
	NEXTFLOWCONFIGOUTPUTDIRECTORY=${10}
	KEYNAME=${11}
	#VERBOSE=

	echo "STACKNAME=$STACKNAME" >> $BATCHAWSCONFIGFILE
	echo "KEYNAME=$KEYNAME" >> $BATCHAWSCONFIGFILE
	echo "COMPUTEENVIRONMENTNAME=$COMPUTEENVIRONMENTNAME"  >> $BATCHAWSCONFIGFILE
	echo "QUEUENAME=$QUEUENAME"  >> $BATCHAWSCONFIGFILE
	echo "SPOTPERCENT=$SPOTPERCENT"  >> $BATCHAWSCONFIGFILE
	echo "EBSVOLUMESIZEGB=$EBSVOLUMESIZEGB" >> $BATCHAWSCONFIGFILE
	echo "MAXCPU=$MAXCPU"  >> $BATCHAWSCONFIGFILE
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
	#
	#######################################################################################
	echo "----------------------------------------------------------------------"
	echo "0.) S3 Bucket: "
	echo "----------------------------------------------------------------------"
	#TODO: rand generator not yet tested on LINUX:
	#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
	#TODO: set more permissions
	#$STACKNAME
	#S3BUCKETNAME
	#check for BLJ bucket (TODO: turn this into a function)
	if [ -z $S3BUCKETNAME ]; then
		s3Tools.sh $STACKNAME create autogenerate createdirstructure
	fi

	#######################################################################################
	#STACK and Cloudformation Parameters 
	#######################################################################################
	#TODO: allow for custom stackfile
	STACKFILE=${BATCHAWSDEPLOY_HOME}BLJStackEFS.yml
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
	# createRolesAndComputeEnv.sh, 2x createcloudformationstack.sh, getcloudformationstack.sh
	if [ "$stackstatus" == "CREATE_COMPLETE" ]; then
		echo $stackstatus
	else
		createcloudformationstack.sh ${STACKNAME} $STACKFILE ParameterKey=\"NetworkAccessIP\",ParameterValue="$MYPUBLICIPADDRESS"
		which createcloudformationstack.sh
	fi
	#######################################################################################
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
		echo "----------------------------------------------------------------------------------------------"
		echo "2.) creating Compute Environment and Job Queue   ---------------------------------------------"
		echo "creating compute environment: $COMPUTEENVIRONMENTNAME"
		echo "----------------------------------------------------------------------------------------------"

		COMPUTERESOURCES="type=SPOT,minvCpus=0,maxvCpus=$MAXCPU,desiredvCpus=$DESIREDCPUS,instanceTypes=optimal,
		imageId=$IMAGEID,subnets=$SUBNETS,securityGroupIds=$BATCHSECURITYGROUP,ec2KeyPair=$KEYNAME,
		instanceRole=$INSTANCEROLE,bidPercentage=$SPOTPERCENT,spotIamFleetRole=$IAMFLEETROLE,
		launchTemplate={launchTemplateId=$BATCHNODELAUNCHTEMPLATEID}"
		
		COMPUTERESOURCES="$(echo -e "${COMPUTERESOURCES}" | tr -d '[:space:]')"


		echo "COMPUTEENVIRONMENTNAME=$COMPUTEENVIRONMENTNAME"
		echo "SERVICEROLE=$SERVICEROLE"
		echo "COMPUTERESOURCES=$COMPUTERESOURCES"
		echo ""
		#batchCreateOutput=$(aws batch create-compute-environment --compute-environment-name $COMPUTEENVIRONMENTNAME
		# --type MANAGED --state ENABLED --service-role ${SERVICEROLE} --compute-resources "$COMPUTERESOURCES")

		batchCreateOutput=$(aws batch create-compute-environment --compute-environment-name $COMPUTEENVIRONMENTNAME \
		--type MANAGED --state ENABLED --service-role ${SERVICEROLE} \
		--compute-resources "$COMPUTERESOURCES")
		echo "$batchCreateOutput"
		sleepProgressBar.sh 3 4

		#######################################################################################
		#2.a) Create Job Queue
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		echo "creating Job Queue: $QUEUENAME"
		queueCreateOutput=$(aws batch create-job-queue --job-queue-name $QUEUENAME \
			--compute-environment-order order=0,computeEnvironment=$COMPUTEENVIRONMENTNAME  \
			--priority $COMPUTEENVPRIORITY \
			--state ENABLED)
		echo $queueCreateOutput
		echo "----------------------------------------------------------------------------------------------"
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
		#BLJBatchJobsDeployOutput=$(updateBatchJobDefinitions.sh $DOCKERREPOSEARCHSTRING $DOCKERRREPOVERSION 
		#                          $JOBROLEARN $JOBVCPUS $JOBMEMORY $STACKNAME)  #$JOBDEFPREFIX
		BLJBatchJobsDeployOutput=$(updateBatchJobDefinitions.sh $STACKNAME)
		echo "$BLJBatchJobsDeployOutput"
		echo "$BLJBatchJobsDeployOutput" >> $BATCHAWSCONFIGFILE
		echo "----------------------------------------------------------------------------------------------"

		echo "----------------------------------------------------------------------------------------------"
		echo "4.) Print Nextflow Config   ------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"
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
		echo "$NEXTFLOWCONFIGOUTPUTDIRECTORYconfig"
		echo "$BATCHAWSCONFIGFILE"
		echo "-----------------------------------------------------------------------------------"
		echo "10.a) Launch EC2 and run script directly:  ----------------------------------------"
		echo "    -This option runs a script directly through ssh on the head node"
		echo "launchEC2Node.sh runscript $STACKNAME HeadNode t2.micro startHeadNodeGui.sh"
		echo "-----------------------------------------------------------------------------------"		
		echo "10.b) Launch EC2 and connect directly:  -------------------------------------------"
		echo "     -This option runs an EC2 instance, copies associated credentials and"
		echo "     creates an ssh connect directly to the headnode"
		echo "launchEC2Node.sh directconnect $STACKNAME HeadNode t2.micro"
		echo "-----------------------------------------------------------------------------------"

	else
		echo "stack could not be found or created"
	fi
else
	echo "Your command line contains $# arguments"
	echo "usage: 12 arguments: "
	echo -n " createRolesAndComputeEnv.sh STACKNAME COMPUTEENVIRONMENTNAME QUEUENAME SPOTPERCENT MAXCPU DEFAULTAMI "
	echo "CUSTOMAMIFOREFS EBSVOLUMESIZEGB EFSPERFORMANCEMODE DOCKERREPOSEARCHSTRING"

fi

#TODO: more error handling about creation of compute environmet and all necessary resources
#TODO: See error screenshot created 2018-10-24- Around 12:58pm  Wrong ECSInstance role???!
#TODO: Check for errors occassionally in malformed Environment or Queue (see screenshot and compute environment 10?  "Status")

#TODO: fix arn gets from cloudformation output
#TODO: check that all instance profiles and roles exist in advance.

#TODO: try putting the key parameter back into the batch

# important note: not having S3 access in the original template was causing S3 puts to fail from nextflow running on the instance:
# https://groups.google.com/forum/#!msg/nextflow/87hI5C831Ok/2pgdP5FOBwAJ

#createRolesAndComputeEnv.sh BLJStack1 BLJComputeEnvironment1 BLJQueue1 60 1024
#TO READ: https://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-sg.html#configuring-a-security-group


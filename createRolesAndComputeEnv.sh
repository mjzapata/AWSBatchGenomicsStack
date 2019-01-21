#!/bin/bash

# This script creates the IAM roles and compute environment necessary to run the BioLockJ Genomics pipeline
# variable names and iam template drawn fromfrom the AWS batch genomics tutorial pipeline (below) and modified to work with NextFlow.
# https://github.com/aws-samples/aws-batch-genomics/blob/master/README.md

#NOTE: On the "BASTIONSECURITYGROUP", Currently, for security, this restricts access to a range of IP addresses.  
#NOTE: All ports will appear blocked if your public IP address changes from the security group was created.  

#Things only created once: IAM stack, security group, network (one public, one private/or use the default?  What about one in between???)

#Questions for Sarah:  EBS.  Am I provisioning 1TB for one instance or for each instance?
# subnets? Security groups?  Which do I create, need a public IP?

#TODO: check for manager API, and various compute-node APIs
#TODO: There are currently several hardcoded values for us-east-1
#TODO: create High and low priority like in the tutorial later, with linked Queues and one that is ON DEMAND
#TODO: autocreate an AIM role with the minimal capabilities and paste it into nextflow output
# EFS: This operation requires permissions for the elasticfilesystem:CreateFileSystem action.

#TODO: validate IP ADDRESS

#TODO: EFS
# The PerformanceMode of the file system.   https://docs.aws.amazon.com/cli/latest/reference/efs/create-file-system.html
# We recommend generalPurpose performance mode for most file systems. 
#File systems using the maxIO performance mode can scale to higher 
#levels of aggregate throughput and operations per second with a tradeoff of slightly higher 
#latencies for most file operations. This can't be changed after the file system has been created.


#PUBLIC image created 12_12_2018
#BLJAMImanager-50GB_DOCKER   ami-01a9c10af27d4d2a8    725685564787/BLJAMImanager-50GB_DOCKER    725685564787
#output this: 
#output 

#TODO: error handling for compute environment and job queue that already exist

#TODO: Automatically print out nextflow.config template, filled in.
#  including the access key and secret key?  restrict file access for config file to "user"??  
#   or should I use the .pem

#TODO: might delete the original compute environments since they have a different AMI??
#TODO: create a random S3 bucket, try to keep it as empty as possible
#TODO: make printnextflow more generic so it can be called with just a stackname?

#TODO: hardcoded region in the progress of EC2 deployment and cloudformation

#NOTE: You get a maximum of 5 VPCS per region, each different stack name creates its own VPC
SECONDS=0

if [ $# -eq 16 ]; then

	STACKNAME=$1
	COMPUTEENVIRONMENTNAME=$2
	QUEUENAME=$3
	SPOTPERCENT=$4
	MAXCPU=$5
	DEFAULTAMI=$6
	CUSTOMAMIFOREFS=$7
	EBSVOLUMESIZEGB=$8
	EFSPERFORMANCEMODE=$9
	DOCKERREPOSEARCHSTRING=${10}
	AWSCONFIGOUTPUTDIRECTORY=${11}
	AWSCONFIGFILENAME=${12}
	NEXTFLOWCONFIGOUTPUTDIRECTORY=${13}
	REGION=${14}
	KEYNAME=${15}
	S3BUCKETNAME=${16}
	#VERBOSE=$7
	#IMAGEID=$4
	echo "STACKNAME=$STACKNAME" >> $AWSCONFIGFILENAME
	echo "AWSCONFIGOUTPUTDIRECTORY=$AWSCONFIGOUTPUTDIRECTORY"  >> $AWSCONFIGFILENAME
	echo "KEYNAME=$KEYNAME" >> $AWSCONFIGFILENAME
	echo "COMPUTEENVIRONMENTNAME=$COMPUTEENVIRONMENTNAME"  >> $AWSCONFIGFILENAME
	echo "QUEUENAME=$QUEUENAME"  >> $AWSCONFIGFILENAME
	echo "SPOTPERCENT=$SPOTPERCENT"  >> $AWSCONFIGFILENAME
	echo "EBSVOLUMESIZEGB=$EBSVOLUMESIZEGB" >> $AWSCONFIGFILENAME
	echo "MAXCPU=$MAXCPU"  >> $AWSCONFIGFILENAME
	echo "DEFAULTAMI=$DEFAULTAMI"  >> $AWSCONFIGFILENAME
	echo "DOCKERREPOSEARCHSTRING=$DOCKERREPOSEARCHSTRING"  >> $AWSCONFIGFILENAME
	echo "REGION=$REGION" >> $AWSCONFIGFILENAME

	ACCOUNTID=$(./getawsaccountid.sh)
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	DESIREDCPUS=0 #this is the minimum reserved CPUS.  Specifying more than 0 will waste money unless you are putting out batch jobs 24/7
	echo "DESIREDCPUS=$DESIREDCPUS" >> $AWSCONFIGFILENAME

	#TODO: create a seperate script for the compute environment
	#TODO: for S3 in regions outside us-east-1 https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html 
	#computeenvstatus=$()

	#AMI Parameters
	#this is only the instance type for creating AMIs
	INSTANCETYPEFORAMICREATION=t2.micro 
	TEMPLATEIMAGEID=ami-0b9a214f40c38d5eb  #latest as of 2018oct17
	#EBSVOLUMESIZEGB="50"
	#Additional identifiers for AMI
	AMIIDENTIFIER=manager
	IMAGETAG=ImageRole
	IMAGETAGVALUE=BLJManage
	EFSTAG=BLJEFSPerformanceMode
	EFSTAGVALUE=$EFSPERFORMANCEMODE
	#Compute Environment Parameters
	#TODO: check if compute environment exists!!!
	COMPUTEENVPRIORITY=10
	echo "COMPUTEENVPRIORITY=$COMPUTEENVPRIORITY"

	#######################################################################################
	#0.) S3 Bucket
	# Check if S3 bucket with name beginning with $STACKNAME exists. If not, create it.
	# Note: the S3 buckets must be GLOBALLY unique. A random string is appended to the stackname to make duplicates less probably
	#
	#######################################################################################
	echo "----------------------------------------------------------------------"
	echo "0.) S3 Bucket: "
	echo "----------------------------------------------------------------------"
	#TODO: rand generator not yet tested on LINUX:
	#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
	#TODO: set more permissions
	#$STACKNAME
	#REGION
	#S3BUCKETNAME
	#check for BLJ bucket (TODO: turn this into a function)
	echo "looking for bucket: $S3BUCKETNAME"
	echo "forcing bucket names to lowercase"
	STACKNAMELOWERCASE=$(echo "$STACKNAME" | tr '[:upper:]' '[:lower:]')
	S3BUCKETNAME=$(echo "$S3BUCKETNAME" | tr '[:upper:]' '[:lower:]')

	IFS=$'\t' #necessary to get tabs to parse correctly
	if [[ $S3BUCKETNAME == 'autogenerate' ]]; then
		nametocheck=$STACKNAMELOWERCASE
		s3bucketlist="$(aws s3api list-buckets)"
		matchingbucket=$(echo $s3bucketlist | grep BUCKETS | grep $nametocheck)
		bucketexists=$(echo -n $matchingbucket | wc -m)
		if [[ $bucketexists -gt 1 ]]; then
			S3BUCKETNAME=$(echo $matchingbucket  | awk '//{print $3}')
			echo "Bucket EXISTS with previously randomly generated name: $S3BUCKETNAME"
		else
			#create a new bucket with name $STACKNAMELOWERCASE followed by a random string
			randlength=24
			randstring=$(cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c $randlength)
			S3BUCKETNAME=${STACKNAMELOWERCASE}-${randstring}
			s3CreateString=$(aws s3api create-bucket --bucket $S3BUCKETNAME --region $REGION)
			echo "Bucket CREATED with randomly generated name: $S3BUCKETNAME"
			echo "$s3CreateString"
		fi
	else
		nametocheck=$S3BUCKETNAME
		s3bucketlist=$(aws s3api list-buckets)
		# grep -w to check for an exact match for the bucketname
		matchingbucket=$(echo $s3bucketlist | grep -w $nametocheck)
		bucketexists=$(echo -n $matchingbucket | wc -m)
		if [[ $bucketexists -gt 1 ]]; then
			#S3BUCKETNAME=$(echo $matchingbucket  | awk '//{print $3}')
			echo "matchingbucket named:  $matchingbucket"
			echo "Bucket EXISTS with name: $S3BUCKETNAME"
		else
			s3CreateString=$(aws s3api create-bucket --bucket $S3BUCKETNAME --region $REGION)
			echo "Bucket CREATED with name: $S3BUCKETNAME"
			echo "$s3CreateString"
		fi
	fi
	echo "S3BUCKETNAME=$S3BUCKETNAME" >> $AWSCONFIGFILENAME

	#######################################################################################
	#STACK and Cloudformation Parameters 
	#######################################################################################
	STACKFILE=BLJStackEFS.yml
	echo "STACKFILE=$STACKFILE" >> $AWSCONFIGFILENAME
	# reduce the last number to be more leniant about ip a ddresses, for example if a university has multiple IPs
	#Get local public IPaddress https://askubuntu.com/questions/95910/command-for-determining-my-public-ip 
	# curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'  
	MYPUBLICIPADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
	MASK=32
	MYPUBLICIPADDRESS=${MYPUBLICIPADDRESS}"/"${MASK}
	echo "MYPUBLICIPADDRESS=$MYPUBLICIPADDRESS" >> $AWSCONFIGFILENAME

	#1.) Check for key and create if it doesn't exist.  This is a keypair for ssh into EC2.
	./awskeypair.sh create $KEYNAME ${AWSCONFIGOUTPUTDIRECTORY}
	#TODO: 1.a) also create secret access key: aws iam create-access-key --user-name  for nextflow login instead of SSH
	#option to create and delete one of these on every run for extra security??????
	#TODO: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey_CLIAPI

	#######################################################################################
	#1.) check if stack exists
	# If it doesn't, ask if you want to create it
	#######################################################################################
	echo "----------------------------------------------------------------------------------------------"
	echo "1.) Deploy Cloudformation Stack  -------------------------------------------------------------"
	echo "----------------------------------------------------------------------------------------------"
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	if [ "$stackstatus" == "Stack exists" ]; then
		echo $stackstatus
	else
		./createcloudformationstack.sh ${STACKNAME} $STACKFILE ParameterKey=\"NetworkAccessIP\",ParameterValue="$MYPUBLICIPADDRESS"
	fi
	#######################################################################################
	#2.) check if stack exists once more
	#######################################################################################
	stackstatus=$(./getcloudformationstack.sh $STACKNAME)
	if [ "$stackstatus" == "Stack exists" ]; then
		SERVICEROLE=$(./getcloudformationstack.sh $STACKNAME BatchServiceRoleArn)
		echo "SERVICEROLE=$SERVICEROLE" >> $AWSCONFIGFILENAME
		#TODO: check these aren't empty
		IAMFLEETROLE=$(./getcloudformationstack.sh $STACKNAME SpotIamFleetRoleArn)
		IAMFLEETROLE=arn:aws:iam::${ACCOUNTID}:role/${IAMFLEETROLE}
		echo "IAMFLEETROLE=$IAMFLEETROLE" >> $AWSCONFIGFILENAME
		JOBROLEARN=$(./getcloudformationstack.sh $STACKNAME ECSTaskRole)
		echo "JOBROLEARN=$JOBROLEARN" >> $AWSCONFIGFILENAME
		
		#INSTANCEROLE=$(./getcloudformationstack.sh $STACKNAME EcsInstanceRoleArn)
		#INSTANCEROLE=arn:aws:iam::${ACCOUNTID}:role/${INSTANCEROLE}
		INSTANCEROLE=$(./getcloudformationstack.sh $STACKNAME IamInstanceProfileArn)
		INSTANCEROLE=arn:aws:iam::${ACCOUNTID}:instance-profile/${INSTANCEROLE}
		echo "INSTANCEROLE=$INSTANCEROLE" >> $AWSCONFIGFILENAME

		#Note: creating a security group with IP rules?  See  Page 6 of Creating a new AMI
		# allows security group creation for each instance?  Public for web facing, private for batch?
		BASTIONSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BastionSecurityGroup)
		BATCHSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BatchSecurityGroup)  #TODO: change the json and this to have a name that returns a different value
		#BATCHSECURITYGROUP=$BASTIONSECURITYGROUP  #TODO delete this and uncomment later

		SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"

		echo "BATCHSECURITYGROUP=$BATCHSECURITYGROUP" >> $AWSCONFIGFILENAME
		echo "BASTIONSECURITYGROUP=$BASTIONSECURITYGROUP" >> $AWSCONFIGFILENAME
		SUBNETS=$(./getcloudformationstack.sh $STACKNAME Subnet)  #replaced getsubnets
		echo "SUBNETS=$SUBNETS" >> $AWSCONFIGFILENAME
		efsID=$(./getcloudformationstack.sh $STACKNAME FileSystemId)

		LAUNCHTEMPLATEID=$(./getcloudformationstack.sh $STACKNAME LaunchTemplateId)
		echo "LAUNCHTEMPLATEID=$LAUNCHTEMPLATEID" >> $AWSCONFIGFILENAME
		#Name might be better to use later, will need to label it as an output under outputs! 
		 #LaunchTemplateName=$(./getcloudformationstack.sh $STACKNAME LaunchTemplateName)


        #######################################################################################
		#3.) Check for AMI
		#######################################################################################
		#3.a) Check if default AMI exists
		# if the default AMI is not found OR if the user has specified "no" as the DEFAULTAMI
		# then a custom AMI will be created
		if [[ $DEFAULTAMI == "no" ]]; then
			IMAGEIDStatus="NA"
		else
			IMAGEIDDStatus=$(./getec2images.sh $DEFAULTAMI status)
			echo "imageIDStatus=$imageIDStatus"
			imageTagStatus=$(./getec2images.sh tags $IMAGETAG $IMAGETAGVALUE)
			echo "imageTagStatus=$imageTagStatus"
			imageExistWordCount=$(echo -n $imageTagStatus | wc -m)
		fi

		if [[ $imageIDStatus == "available" && $DEFAULTAMI != "no" ]]; then
			echo "Found default BLJ image with ID: ${DEFAULTAMI}"
			IMAGEID=$DEFAULTAMI
		elif [[ $imageExistWordCount -lt 2 ]]; then
			echo "CREATING new AMI...."
			EC2RUNARGUMENT="createAMI"
			INSTANCENAME="CREATEAMI"
			COPYCONFIG=no
		#3.b)  Check if AMI with custom tags exists
			#TODO: clean up the getec2images call. maybe rename functions
			#If it doesn't exist ask if you want to create an AMI using the 
			#if [ $imageIDStatus == "image not found" ]; then
			while true; do
	    		read -p "Image with tag: ${IMAGETAG}, value: ${IMAGETAGVALUE} does not exist. Do you want to create it?: " yn
	    		case $yn in
	        		[Yy]* ) ./launchEC2.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPEFORAMICREATION $KEYNAME $EBSVOLUMESIZEGB $SUBNETS $BASTIONSECURITYGROUP \
											$INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID $COPYCONFIG configureEC2forAMI.sh \
											$AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE; break;;
	        		[Nn]* ) exit;;
	        		* ) echo "Please answer yes or no.";;
	    		esac
			done
			# ./launchEC2.sh $STACKNAME $TEMPLATEIMAGEID $INSTANCETYPEFORAMICREATION $KEYNAME $EBSVOLUMESIZEGB $SUBNETS $BASTIONSECURITYGROUP \
			# 				$MYPUBLICIPADDRESS $INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID configureEC2forAMI.sh \
			# 				$AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE
			#image ID is the 6th column in the outputstring
			IMAGEID=$(echo $imageTagStatus | grep IMAGES | grep ami | awk '//{print $6}')

		fi
		echo "IMAGEID=$IMAGEID" >> $AWSCONFIGFILENAME



		################################################################################################
		#4.) Create Batch Computing environment
		####################################################################################################
		echo "----------------------------------------------------------------------------------------------"
		echo "4.) creating compute environment: $COMPUTEENVIRONMENTNAME       ------------------------------"
		echo "----------------------------------------------------------------------------------------------"
		echo "creating compute environment: $COMPUTEENVIRONMENTNAME"
		batchCreateOutput=$(aws batch create-compute-environment --compute-environment-name $COMPUTEENVIRONMENTNAME \
		--type MANAGED --state ENABLED --service-role ${SERVICEROLE} \
		--compute-resources type=SPOT,minvCpus=0,maxvCpus=$MAXCPU,desiredvCpus=$DESIREDCPUS,instanceTypes=optimal,imageId=$IMAGEID,subnets=$SUBNETS,securityGroupIds=$BATCHSECURITYGROUP,ec2KeyPair=$KEYNAME,instanceRole=$INSTANCEROLE,bidPercentage=$SPOTPERCENT,spotIamFleetRole=$IAMFLEETROLE,launchTemplate={launchTemplateId=$LAUNCHTEMPLATEID})
		echo "$batchOutput"
		echo "$batchCreateOutput"
		./sleepProgressBar.sh 3 4


		#######################################################################################
		#5.) Create Job Queue
		#######################################################################################
		queueCreateOutput=$(aws batch create-job-queue --job-queue-name $QUEUENAME \
			--compute-environment-order order=0,computeEnvironment=$COMPUTEENVIRONMENTNAME  \
			--priority $COMPUTEENVPRIORITY \
			--state ENABLED)

		echo $queueCreateOutput
		

		#######################################################################################
		#6.) Print success message
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		timeinminutes=$(awk "BEGIN {print $SECONDS/60}")
		echo "SUCCESS!"
		echo "BLJ Stack, AMI, and compute environment deployed in: $timeinminutes minutes ($SECONDS seconds)"
		echo "----------------------------------------------------------------------------------------------"

		#######################################################################################
		#7.) Create Job Definition
		# Create ONE Job defintion for ONE container
		# The purpose of creating a seperate job definition to work with nextflow is that
		# containers need to be declared as "priviledged" in order to mount EFS volumes.
		# This script will have to be run for every job definition you wish to run
		# and only re-run if you want to change the actual name of the IMAGE
		# this will then output a new nextflow config file
		# Note, the cpus and memory can be overridden at runtime in each nextflow process.
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		echo "7.) Create Job Definition  -------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"
		DOCKERRREPOVERSION="latest"
		JOBVCPUS=2      #can be overridden at runtime
		JOBMEMORY=1000	#can be overriden at runtime
		#JOBDEFPREFIX=$(tr -s /: _ <<< "$DOCKERREPOSEARCHSTRING") #biolockj
		# outputs two columns 
		#DOCKER_IMAGE    JOBDEFINITION   Tab hack with awk
		BLJBatchJobsDeployOutput=$(./updateBatchJobDefinitions.sh $DOCKERREPOSEARCHSTRING $DOCKERRREPOVERSION $JOBROLEARN $JOBVCPUS $JOBMEMORY $STACKNAME)  #$JOBDEFPREFIX
		echo -e "$BLJBatchJobsDeployOutput"
		echo -e $BLJBatchJobsDeployOutput > ${AWSCONFIGOUTPUTDIRECTORY}${STACKNAME}JobDefinitions.tsv
		awk -v OFS="\t" '$1=$1' ${AWSCONFIGOUTPUTDIRECTORY}${STACKNAME}JobDefinitions.tsv

		echo "----------------------------------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"

		#######################################################################################
		#8.) Print Nextflow Config
		#######################################################################################
		echo "----------------------------------------------------------------------------------------------"
		echo "8.) Print Nextflow Config   ------------------------------------------------------------------"
		echo "----------------------------------------------------------------------------------------------"
		echo "copy and paste this into a file named nextflow.config and change the values for accessKey and secretKey"
		AWSACCESSKEY='mysecretaccesskeyid'
		AWSSECRETKEY='mysecretkey'
		nextflowconfig=$(./printnextflowconfig.sh $QUEUENAME $AWSACCESSKEY $AWSSECRETKEY)
		
		echo $nextflowconfig > "${NEXTFLOWCONFIGOUTPUTDIRECTORY}nextflow.config"

	else
		echo "stack could not be found or created"
	fi
else
	echo "Your command line contains $# arguments"
	echo "usage: sixteen arguments: "
	echo " ./createRolesAndComputeEnv.sh STACKNAME COMPUTEENVIRONMENTNAME QUEUENAME SPOTPERCENT MAXCPU DEFAULTAMI CUSTOMAMIFOREFS EBSVOLUMESIZEGB EFSPERFORMANCEMODE DOCKERREPOSEARCHSTRING AWSCONFIGOUTPUTDIRECTORY S3BUCKETNAME"

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


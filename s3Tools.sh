#!/bin/bash
STACKNAME=$1
ARGUMENT=$2
#S3BUCKETNAME=$3 (below)
#createS3DirStructure=$4 (below)

print_error(){
	echo "This script accepts X arguments"
	echo "Usage:
	s3Tools.sh listbuckets 
	s3Tools.sh STACKNAME create S3BUCKETNAME
	s3Tools.sh STACKNAME list
	s3Tools.sh STACKNAME get
	s3Tools.sh STACKNAME copyToS3 FILENAME REMOTEFOLDER
	s3Tools.sh STACKNAME syncToS3 LOCALFOLDER REMOTEFOLDER
	s3Tools.sh STACKNAME syncFromS3 REMOTEFOLDER LOCALFOLDER"
}

if [ $STACKNAME == "listbuckets" ]	
	aws s3 ls
fi

if [ $# -gt 1 ]; then

	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	#Create AWS config file and start writing values
    #this is duplicated in s3Tools.sh and deployBatchEnv.sh
	if [ ! -f $BATCHAWSCONFIGFILE ]; then
        touch "$BATCHAWSCONFIGFILE"
        echo "#!/bin/bash" > $BATCHAWSCONFIGFILE
        echo "" >> $BATCHAWSCONFIGFILE
        echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE" >> $BATCHAWSCONFIGFILE
        REGION=$(aws configure get region)
        echo "REGION=$REGION"
        echo "REGION=$REGION" >> $BATCHAWSCONFIGFILE
    fi
	source $BATCHAWSCONFIGFILE
    #Create AWS config file and start writing values
    #this is duplicated in s3Tools.sh and deployBatchEnv.sh
    # if [ ! -f $BATCHAWSCONFIGFILE ]; then
    #     touch "$BATCHAWSCONFIGFILE"
    #     echo "#!/bin/bash" > $BATCHAWSCONFIGFILE
    #     echo "" >> $BATCHAWSCONFIGFILE
    #     echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE" >> $BATCHAWSCONFIGFILE
    # fi

	########################################
	################ CREATE ################
	########################################
	if [ "$ARGUMENT" == "create" ]; then
		S3BUCKETNAME=$3
		createS3DirStructure=$4
		########## AUTOGENERATE BUCKET NAME ##########
		#TODO: rand generator not yet tested on LINUX:
		#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
		#TODO: set more permissions
		# Check if S3 bucket with name beginning with $STACKNAME exists. If not, create it.
		# Note: the S3 buckets must be GLOBALLY unique. A random string is 
		# appended to the stackname to make duplicates less probably
		echo "forcing bucket names to lowercase"
		STACKNAMELOWERCASE=$(echo "$STACKNAME" | tr '[:upper:]' '[:lower:]')
		S3BUCKETNAME=$(echo "$S3BUCKETNAME" | tr '[:upper:]' '[:lower:]')

		IFS=$'\t' #necessary to get tabs to parse correctly
		if [ $S3BUCKETNAME == 'autogenerate' ] || [ $S3BUCKETNAME == 'autocreate' ]; then
			BUCKETNAMESEPARATOR="-"
			nametocheck=${STACKNAMELOWERCASE}${BUCKETNAMESEPARATOR}
			s3bucketlist="$(aws s3api list-buckets)"
			matchingbucket=$(echo $s3bucketlist | grep BUCKETS | grep $nametocheck)
			bucketexists=$(echo -n $matchingbucket | wc -m)
			if [ $bucketexists -gt 1 ]; then
				S3BUCKETNAME=$(echo $matchingbucket  | awk '//{print $3}')
				echo "Bucket EXISTS with previously randomly generated name: $S3BUCKETNAME"
			else
				#create a new bucket with name $STACKNAMELOWERCASE followed by a random string
				randlength=24
				randstring=$(cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c $randlength)
				S3BUCKETNAME=${STACKNAMELOWERCASE}${BUCKETNAMESEPARATOR}${randstring}
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
		# https://stackoverflow.com/questions/36837975/how-to-create-folder-on-s3-from-ec2-instance
		if [ $createS3DirStructure == "createdirstructure" ]; then
			echo "Creating S3 Directory Structure using s3Tools.sh"
			MAINDIR="/BioSheperd/"
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}pipelines/
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}datasets/
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}databases/
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}/
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}meta/
			aws s3api put-object --bucket $S3BUCKETNAME --key ${MAINDIR}primers/
		fi


		echo "S3BUCKETNAME=$S3BUCKETNAME" >> $BATCHAWSCONFIGFILE
		echo "S3BUCKETNAME=$S3BUCKETNAME"

		S3BUCKETWEBADDRESS="https://s3.console.aws.amazon.com/s3/buckets/${S3BUCKETNAME}"
		S3BUCKETFTPADDRESS="s3://${S3BUCKETNAME}"
		echo "S3BUCKEADDRESS=$S3BUCKETADDRESS" >> $BATCHAWSCONFIGFILE
		echo "S3BUCKEADDRESS=$S3BUCKETADDRESS"

	########################################
	################  LIST  ################
	########################################
	elif [ "$ARGUMENT" == "list" ]; then
		echo "S3BUCKETNAME=$S3BUCKETNAME"	
		aws s3 ls "s3://$S3BUCKETNAME"

	########################################
	#################  GET  ################
	########################################
	elif [ "$ARGUMENT" == "get" ]; then
		#echo test
		echo "get"
		s3Tools.sh $STACKNAME list
	########################################
	#################  CP  ################
	########################################
	elif [ "$ARGUMENT" == "copyToS3" ]; then
		FILENAME=$3
		FOLDER=$4
		#NOTE, MUST put trailing slashes (/) on folder to signify that it is a folder, otherwise
		# it will use the trailing characters as the filename.
		aws s3 cp $FILENAME s3://$S3BUCKETNAME/$FOLDER

	########################################
	############  SYNC TO S3  ##############
	########################################
	elif [ "$ARGUMENT" == "syncToS3" ]; then
		LOCALFOLDER=$3
		REMOTEFOLDER=$4
		aws s3 sync $LOCALFOLDER s3://${S3BUCKETNAME}/${REMOTEFOLDER}
	########################################
	###########  SYNC FROM S3  #############
	########################################
	elif [ "$ARGUMENT" == "syncFromS3" ]; then
		REMOTEFOLDER=$3
		LOCALFOLDER=$4
		aws s3 sync s3://${S3BUCKETNAME}/${REMOTEFOLDER} $LOCALFOLDER

	fi
fi


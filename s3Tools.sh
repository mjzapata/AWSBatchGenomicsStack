#!/bin/bash
STACKNAME=$1
ARGUMENT=$2

print_error(){
	echo "This script accepts X arguments"
	echo "Usage: s3Tools.sh create S3BUCKETNAME STACKNAME"
}

if [ $# -gt 1 ]; then

	AWSCONFIGFILENAME=~/.batchawsdeploy/${STACKNAME}.sh
	source $AWSCONFIGFILENAME
	########################################
	################ CREATE ################
	########################################
	if [ "$ARGUMENT" == "create" ]; then
		S3BUCKETNAME=$3
		########## AUTOGENERATE BUCKET NAME ##########
		#TODO: rand generator not yet tested on LINUX:
		#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
		#TODO: set more permissions
		#$STACKNAME
		#REGION
		#S3BUCKETNAME
		# Check if S3 bucket with name beginning with $STACKNAME exists. If not, create it.
		# Note: the S3 buckets must be GLOBALLY unique. A random string is 
		# appended to the stackname to make duplicates less probably
		echo "looking for bucket: $S3BUCKETNAME"
		echo "forcing bucket names to lowercase"
		STACKNAMELOWERCASE=$(echo "$STACKNAME" | tr '[:upper:]' '[:lower:]')
		S3BUCKETNAME=$(echo "$S3BUCKETNAME" | tr '[:upper:]' '[:lower:]')

		IFS=$'\t' #necessary to get tabs to parse correctly
		if [ $S3BUCKETNAME == 'autogenerate' ] || [ $S3BUCKETNAME == 'autocreate' ]; then
			nametocheck=$STACKNAMELOWERCASE
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
		echo "S3BUCKETNAME=$S3BUCKETNAME"

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
		echo test

	########################################
	#################  CP  ################
	########################################
	elif [ "$ARGUMENT" == "copy" ]; then
		FILENAME=$3
		FOLDER=$4
		#NOTE, MUST put trailing slashes (/) on folder to signify that it is a folder, otherwise
		# it will use the trailing characters as the filename.
		aws s3 cp $FILENAME s3://$S3BUCKETNAME/$FOLDER

	fi
fi


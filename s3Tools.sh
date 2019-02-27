#!/bin/bash
ARGUMENT=$1

print_error(){
	echo "This script accepts X arguments"
	echo "Usage: s3Tools.sh create S3BUCKETNAME STACKNAME"
}

if [ $# -gt 1 ]; then

	S3BUCKETNAME=$2
	
	STACKNAME=$3
	source ~/.profile
	source $AWSCONFIGFILENAME
	AWSCONFIGFILENAME=${BATCHAWSDEPLOY_HOME}${STACKNAME}.sh

	if [ "$ARGUMENT" == "create" ]; then
		########## AUTOGENERATE BUCKET NAME ##########
		echo "----------------------------------------------------------------------"
		echo "0.) S3 Bucket: "
		echo "----------------------------------------------------------------------"
		#TODO: rand generator not yet tested on LINUX:
		#  -https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell 
		#TODO: set more permissions
		#$STACKNAME
		#REGION
		#S3BUCKETNAME
		# Check if S3 bucket with name beginning with $STACKNAME exists. If not, create it.
		# Note: the S3 buckets must be GLOBALLY unique. A random string is appended to the stackname to make duplicates less probably
		echo "looking for bucket: $S3BUCKETNAME"
		echo "forcing bucket names to lowercase"
		STACKNAMELOWERCASE=$(echo "$STACKNAME" | tr '[:upper:]' '[:lower:]')
		S3BUCKETNAME=$(echo "$S3BUCKETNAME" | tr '[:upper:]' '[:lower:]')

		IFS=$'\t' #necessary to get tabs to parse correctly
		if [ $S3BUCKETNAME == 'autogenerate' ]; then
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

	############## LIST BUCKET NAME #########
	elif [ "$ARGUMENT" == "list" ]; then
		echo test
	############## GET FROM BUCKET ##########
	elif [ "$ARGUMENT" == "get" ]; then
		echo test
	############## PUT IN BUCKET ############
	elif [ "$ARGUMENT" == "put" ]; then
		echo test

	fi
fi

